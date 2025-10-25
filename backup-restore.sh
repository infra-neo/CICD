#!/bin/bash
# Backup and Restore Script for CI/CD Environment
# Backs up configurations, properties, and version history

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

function show_usage {
    echo -e "${BLUE}=== CI/CD Backup and Restore Script ===${NC}"
    echo
    echo "Usage: $0 [backup|restore|list] [options]"
    echo
    echo "Commands:"
    echo "  backup              Create a backup of all configurations"
    echo "  restore <backup>    Restore from a specific backup"
    echo "  list                List all available backups"
    echo
    echo "Examples:"
    echo "  $0 backup"
    echo "  $0 restore 20251025_143022"
    echo "  $0 list"
    echo
}

function backup_configs {
    echo -e "${GREEN}=== Starting Backup ===${NC}"
    
    BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"
    mkdir -p "$BACKUP_PATH"
    
    echo -e "${YELLOW}Backup location: $BACKUP_PATH${NC}"
    
    # Backup environment configurations
    echo -e "${YELLOW}Backing up environment configurations...${NC}"
    if [ -d "config/environments" ]; then
        cp -r config/environments "$BACKUP_PATH/"
        echo -e "${GREEN}✓ Environment configurations backed up${NC}"
    fi
    
    # Backup WildFly configuration
    echo -e "${YELLOW}Backing up WildFly configuration...${NC}"
    if docker ps | grep -q "wildfly"; then
        docker exec wildfly tar czf /tmp/wildfly-config.tar.gz \
            /opt/jboss/wildfly/standalone/configuration 2>/dev/null || true
        docker cp wildfly:/tmp/wildfly-config.tar.gz "$BACKUP_PATH/" 2>/dev/null || true
        echo -e "${GREEN}✓ WildFly configuration backed up${NC}"
    else
        echo -e "${YELLOW}⚠ WildFly container not running, skipping${NC}"
    fi
    
    # Backup JBoss configuration
    echo -e "${YELLOW}Backing up JBoss configuration...${NC}"
    if docker ps | grep -q "jboss"; then
        docker exec jboss tar czf /tmp/jboss-config.tar.gz \
            /opt/jboss/wildfly/standalone/configuration 2>/dev/null || true
        docker cp jboss:/tmp/jboss-config.tar.gz "$BACKUP_PATH/" 2>/dev/null || true
        echo -e "${GREEN}✓ JBoss configuration backed up${NC}"
    else
        echo -e "${YELLOW}⚠ JBoss container not running, skipping${NC}"
    fi
    
    # Backup Jenkins jobs
    echo -e "${YELLOW}Backing up Jenkins configuration...${NC}"
    if docker ps | grep -q "jenkins"; then
        docker exec jenkins tar czf /tmp/jenkins-jobs.tar.gz \
            /var/jenkins_home/jobs 2>/dev/null || true
        docker cp jenkins:/tmp/jenkins-jobs.tar.gz "$BACKUP_PATH/" 2>/dev/null || true
        docker exec jenkins tar czf /tmp/jenkins-credentials.tar.gz \
            /var/jenkins_home/credentials.xml \
            /var/jenkins_home/secrets 2>/dev/null || true
        docker cp jenkins:/tmp/jenkins-credentials.tar.gz "$BACKUP_PATH/" 2>/dev/null || true
        echo -e "${GREEN}✓ Jenkins configuration backed up${NC}"
    else
        echo -e "${YELLOW}⚠ Jenkins container not running, skipping${NC}"
    fi
    
    # Backup Nexus configuration
    echo -e "${YELLOW}Backing up Nexus configuration...${NC}"
    if docker ps | grep -q "nexus"; then
        docker exec nexus tar czf /tmp/nexus-config.tar.gz \
            /nexus-data/etc 2>/dev/null || true
        docker cp nexus:/tmp/nexus-config.tar.gz "$BACKUP_PATH/" 2>/dev/null || true
        echo -e "${GREEN}✓ Nexus configuration backed up${NC}"
    else
        echo -e "${YELLOW}⚠ Nexus container not running, skipping${NC}"
    fi
    
    # Backup SonarQube database
    echo -e "${YELLOW}Backing up SonarQube database...${NC}"
    if docker ps | grep -q "postgres"; then
        docker exec postgres pg_dump -U sonar sonarqube > "$BACKUP_PATH/sonarqube.sql" 2>/dev/null || true
        echo -e "${GREEN}✓ SonarQube database backed up${NC}"
    else
        echo -e "${YELLOW}⚠ PostgreSQL container not running, skipping${NC}"
    fi
    
    # Backup build configuration
    echo -e "${YELLOW}Backing up build configuration...${NC}"
    cp build-config.yml "$BACKUP_PATH/" 2>/dev/null || true
    cp docker-compose.yml "$BACKUP_PATH/" 2>/dev/null || true
    cp Jenkinsfile* "$BACKUP_PATH/" 2>/dev/null || true
    echo -e "${GREEN}✓ Build configuration backed up${NC}"
    
    # Create backup manifest
    cat > "$BACKUP_PATH/manifest.txt" << EOF
CI/CD Environment Backup
========================
Timestamp: $TIMESTAMP
Date: $(date)
Hostname: $(hostname)
User: $(whoami)

Contents:
- Environment configurations
- WildFly configuration
- JBoss configuration
- Jenkins jobs and credentials
- Nexus configuration
- SonarQube database
- Build configuration files

Docker Containers Status:
$(docker ps --format "table {{.Names}}\t{{.Status}}")
EOF
    
    # Compress the entire backup
    echo -e "${YELLOW}Compressing backup...${NC}"
    tar czf "$BACKUP_DIR/backup-$TIMESTAMP.tar.gz" -C "$BACKUP_DIR" "$TIMESTAMP"
    
    # Calculate size
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR/backup-$TIMESTAMP.tar.gz" | cut -f1)
    
    echo
    echo -e "${GREEN}=== Backup Complete ===${NC}"
    echo -e "${GREEN}Backup file: $BACKUP_DIR/backup-$TIMESTAMP.tar.gz${NC}"
    echo -e "${GREEN}Backup size: $BACKUP_SIZE${NC}"
    echo
    echo "To restore this backup, run:"
    echo "  $0 restore $TIMESTAMP"
}

function restore_configs {
    RESTORE_TIMESTAMP=$1
    
    if [ -z "$RESTORE_TIMESTAMP" ]; then
        echo -e "${RED}Error: Please specify backup timestamp to restore${NC}"
        echo "Use '$0 list' to see available backups"
        exit 1
    fi
    
    BACKUP_FILE="$BACKUP_DIR/backup-$RESTORE_TIMESTAMP.tar.gz"
    
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}Error: Backup file not found: $BACKUP_FILE${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}=== Starting Restore ===${NC}"
    echo -e "${YELLOW}Restoring from: $BACKUP_FILE${NC}"
    echo
    
    # Extract backup
    echo -e "${YELLOW}Extracting backup...${NC}"
    tar xzf "$BACKUP_FILE" -C "$BACKUP_DIR"
    
    RESTORE_PATH="$BACKUP_DIR/$RESTORE_TIMESTAMP"
    
    # Restore environment configurations
    if [ -d "$RESTORE_PATH/environments" ]; then
        echo -e "${YELLOW}Restoring environment configurations...${NC}"
        cp -r "$RESTORE_PATH/environments" config/
        echo -e "${GREEN}✓ Environment configurations restored${NC}"
    fi
    
    # Restore build configuration
    if [ -f "$RESTORE_PATH/build-config.yml" ]; then
        echo -e "${YELLOW}Restoring build configuration...${NC}"
        cp "$RESTORE_PATH/build-config.yml" .
        echo -e "${GREEN}✓ Build configuration restored${NC}"
    fi
    
    # Restore WildFly configuration
    if [ -f "$RESTORE_PATH/wildfly-config.tar.gz" ] && docker ps | grep -q "wildfly"; then
        echo -e "${YELLOW}Restoring WildFly configuration...${NC}"
        docker cp "$RESTORE_PATH/wildfly-config.tar.gz" wildfly:/tmp/
        docker exec wildfly tar xzf /tmp/wildfly-config.tar.gz -C /
        docker restart wildfly
        echo -e "${GREEN}✓ WildFly configuration restored${NC}"
    fi
    
    # Restore JBoss configuration
    if [ -f "$RESTORE_PATH/jboss-config.tar.gz" ] && docker ps | grep -q "jboss"; then
        echo -e "${YELLOW}Restoring JBoss configuration...${NC}"
        docker cp "$RESTORE_PATH/jboss-config.tar.gz" jboss:/tmp/
        docker exec jboss tar xzf /tmp/jboss-config.tar.gz -C /
        docker restart jboss
        echo -e "${GREEN}✓ JBoss configuration restored${NC}"
    fi
    
    # Restore Jenkins jobs
    if [ -f "$RESTORE_PATH/jenkins-jobs.tar.gz" ] && docker ps | grep -q "jenkins"; then
        echo -e "${YELLOW}Restoring Jenkins configuration...${NC}"
        docker cp "$RESTORE_PATH/jenkins-jobs.tar.gz" jenkins:/tmp/
        docker exec jenkins tar xzf /tmp/jenkins-jobs.tar.gz -C /
        docker restart jenkins
        echo -e "${GREEN}✓ Jenkins configuration restored${NC}"
    fi
    
    # Restore SonarQube database
    if [ -f "$RESTORE_PATH/sonarqube.sql" ] && docker ps | grep -q "postgres"; then
        echo -e "${YELLOW}Restoring SonarQube database...${NC}"
        docker exec -i postgres psql -U sonar sonarqube < "$RESTORE_PATH/sonarqube.sql" 2>/dev/null || true
        docker restart sonarqube
        echo -e "${GREEN}✓ SonarQube database restored${NC}"
    fi
    
    echo
    echo -e "${GREEN}=== Restore Complete ===${NC}"
    echo -e "${YELLOW}You may need to restart services for all changes to take effect${NC}"
    echo "Run: docker compose restart"
}

function list_backups {
    echo -e "${BLUE}=== Available Backups ===${NC}"
    echo
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR/*.tar.gz 2>/dev/null)" ]; then
        echo -e "${YELLOW}No backups found${NC}"
        return
    fi
    
    echo -e "${BLUE}Timestamp          | Size    | Date${NC}"
    echo "-------------------+---------+-------------------------"
    
    for backup in $BACKUP_DIR/backup-*.tar.gz; do
        if [ -f "$backup" ]; then
            TIMESTAMP=$(basename "$backup" | sed 's/backup-\(.*\)\.tar\.gz/\1/')
            SIZE=$(du -sh "$backup" | cut -f1)
            DATE=$(date -r "$backup" "+%Y-%m-%d %H:%M:%S")
            printf "%-18s | %-7s | %s\n" "$TIMESTAMP" "$SIZE" "$DATE"
        fi
    done
    
    echo
    echo "To restore a backup, run:"
    echo "  $0 restore <timestamp>"
}

# Main script
case "${1:-}" in
    backup)
        backup_configs
        ;;
    restore)
        restore_configs "$2"
        ;;
    list)
        list_backups
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
