#!/usr/bin/env python3
"""
GitLab CI/CD Configuration Loader

Este script automatiza la carga de configuración desde un archivo Excel
hacia GitLab CI/CD variables y genera archivos de configuración usando templates.

Autor: Automation Team
Fecha: 2026-01-21
"""

import os
import sys
import logging
from pathlib import Path
from typing import Dict, List, Optional

import pandas as pd
import gitlab
from jinja2 import Environment, FileSystemLoader, TemplateNotFound

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class ConfigLoader:
    """Clase para cargar configuración desde Excel hacia GitLab CI/CD"""

    def __init__(self, excel_path: str, gitlab_url: str, token: str, project_id: str):
        """
        Inicializa el ConfigLoader.

        Args:
            excel_path: Ruta al archivo Excel con la configuración
            gitlab_url: URL de la instancia de GitLab
            token: Token de autenticación de GitLab
            project_id: ID del proyecto en GitLab
        """
        self.excel_path = excel_path
        self.gitlab_url = gitlab_url
        self.token = token
        self.project_id = project_id
        self.gl = None
        self.project = None
        self.variables_df = None
        self.build_info_df = None

    def connect_gitlab(self) -> bool:
        """
        Conecta con GitLab usando la API.

        Returns:
            True si la conexión fue exitosa, False en caso contrario
        """
        try:
            logger.info(f"Conectando con GitLab en {self.gitlab_url}")
            self.gl = gitlab.Gitlab(self.gitlab_url, private_token=self.token)
            self.gl.auth()
            
            logger.info(f"Obteniendo proyecto con ID: {self.project_id}")
            self.project = self.gl.projects.get(self.project_id)
            logger.info(f"Conexión exitosa al proyecto: {self.project.name}")
            return True
        except gitlab.exceptions.GitlabAuthenticationError as e:
            logger.error(f"Error de autenticación: {e}")
            return False
        except gitlab.exceptions.GitlabGetError as e:
            logger.error(f"Error al obtener el proyecto: {e}")
            return False
        except Exception as e:
            logger.error(f"Error inesperado al conectar con GitLab: {e}")
            return False

    def read_excel(self) -> bool:
        """
        Lee el archivo Excel y carga las hojas en DataFrames.

        Returns:
            True si la lectura fue exitosa, False en caso contrario
        """
        try:
            logger.info(f"Leyendo archivo Excel: {self.excel_path}")
            
            if not os.path.exists(self.excel_path):
                logger.error(f"El archivo {self.excel_path} no existe")
                return False

            # Leer hoja de Variables
            try:
                self.variables_df = pd.read_excel(
                    self.excel_path,
                    sheet_name='Variables',
                    engine='openpyxl'
                )
                logger.info(f"Hoja 'Variables' leída: {len(self.variables_df)} filas")
            except ValueError as e:
                logger.warning(f"No se pudo leer la hoja 'Variables': {e}")
                self.variables_df = pd.DataFrame()

            # Leer hoja de Build_Info
            try:
                self.build_info_df = pd.read_excel(
                    self.excel_path,
                    sheet_name='Build_Info',
                    engine='openpyxl'
                )
                logger.info(f"Hoja 'Build_Info' leída: {len(self.build_info_df)} filas")
            except ValueError as e:
                logger.warning(f"No se pudo leer la hoja 'Build_Info': {e}")
                self.build_info_df = pd.DataFrame()

            return True
        except Exception as e:
            logger.error(f"Error al leer el archivo Excel: {e}")
            return False

    def set_gitlab_variables(self) -> bool:
        """
        Configura las variables de CI/CD en GitLab desde el Excel.

        Returns:
            True si todas las variables se configuraron correctamente
        """
        if self.variables_df is None or self.variables_df.empty:
            logger.warning("No hay variables para configurar")
            return True

        success = True
        variables_count = 0
        updated_count = 0
        created_count = 0

        logger.info("Configurando variables de CI/CD en GitLab...")

        for _, row in self.variables_df.iterrows():
            try:
                key = str(row['Key']).strip()
                value = str(row['Value']).strip()
                environment = str(row.get('Environment', 'ALL')).strip().upper()
                protected = str(row.get('Protected', 'False')).strip().lower() == 'true'

                # Mapear el environment a environment_scope
                if environment == 'ALL' or environment == '*':
                    environment_scope = '*'
                elif environment == 'QA':
                    environment_scope = 'qa'
                elif environment == 'PRE':
                    environment_scope = 'pre'
                elif environment == 'PROD':
                    environment_scope = 'prod'
                else:
                    environment_scope = environment.lower()

                logger.info(f"Procesando variable: {key} (scope: {environment_scope})")

                # Intentar actualizar la variable si existe
                try:
                    # Buscar variable existente con el mismo key y scope
                    existing_var = None
                    for var in self.project.variables.list(all=True):
                        if var.key == key and var.environment_scope == environment_scope:
                            existing_var = var
                            break

                    if existing_var:
                        # Actualizar variable existente
                        existing_var.value = value
                        existing_var.protected = protected
                        existing_var.save()
                        logger.info(f"✓ Variable actualizada: {key}")
                        updated_count += 1
                    else:
                        # Crear nueva variable
                        self.project.variables.create({
                            'key': key,
                            'value': value,
                            'environment_scope': environment_scope,
                            'protected': protected
                        })
                        logger.info(f"✓ Variable creada: {key}")
                        created_count += 1

                    variables_count += 1

                except gitlab.exceptions.GitlabCreateError as e:
                    logger.error(f"✗ Error al crear variable {key}: {e}")
                    success = False
                except gitlab.exceptions.GitlabUpdateError as e:
                    logger.error(f"✗ Error al actualizar variable {key}: {e}")
                    success = False

            except KeyError as e:
                logger.error(f"Columna faltante en el Excel: {e}")
                success = False
            except Exception as e:
                logger.error(f"Error procesando variable: {e}")
                success = False

        logger.info(f"\nResumen: {variables_count} variables procesadas")
        logger.info(f"  - Creadas: {created_count}")
        logger.info(f"  - Actualizadas: {updated_count}")

        return success

    def generate_config_files(self, templates_dir: str = 'templates', 
                            output_dir: str = 'generated_configs') -> bool:
        """
        Genera archivos de configuración usando plantillas Jinja2.

        Args:
            templates_dir: Directorio con las plantillas Jinja2
            output_dir: Directorio donde guardar los archivos generados

        Returns:
            True si los archivos se generaron correctamente
        """
        try:
            # Crear directorio de salida si no existe
            output_path = Path(output_dir)
            output_path.mkdir(parents=True, exist_ok=True)
            logger.info(f"Directorio de salida: {output_path.absolute()}")

            # Verificar si existe el directorio de templates
            if not os.path.exists(templates_dir):
                logger.warning(f"Directorio de templates '{templates_dir}' no existe. Saltando generación de archivos.")
                return True

            # Configurar Jinja2
            env = Environment(loader=FileSystemLoader(templates_dir))

            # Preparar contexto de datos para las plantillas
            context = {
                'variables': {},
                'build_info': {}
            }

            # Convertir variables a diccionario por environment
            if self.variables_df is not None and not self.variables_df.empty:
                for _, row in self.variables_df.iterrows():
                    key = str(row['Key']).strip()
                    value = str(row['Value']).strip()
                    environment = str(row.get('Environment', 'ALL')).strip().upper()
                    
                    if environment not in context['variables']:
                        context['variables'][environment] = {}
                    context['variables'][environment][key] = value

            # Convertir build_info a diccionario
            if self.build_info_df is not None and not self.build_info_df.empty:
                for _, row in self.build_info_df.iterrows():
                    component = str(row.get('Component', '')).strip()
                    if component:
                        context['build_info'][component] = {
                            'version': str(row.get('Version', '')).strip(),
                            'maven_profile': str(row.get('Maven_Profile', '')).strip()
                        }

            # Renderizar todas las plantillas encontradas
            template_files = list(Path(templates_dir).glob('*.j2'))
            
            if not template_files:
                logger.warning(f"No se encontraron plantillas (.j2) en {templates_dir}")
                return True

            logger.info(f"Generando {len(template_files)} archivos de configuración...")

            for template_file in template_files:
                try:
                    template_name = template_file.name
                    output_name = template_name.replace('.j2', '')
                    
                    logger.info(f"Renderizando template: {template_name}")
                    template = env.get_template(template_name)
                    rendered_content = template.render(**context)
                    
                    # Guardar archivo renderizado
                    output_file = output_path / output_name
                    with open(output_file, 'w', encoding='utf-8') as f:
                        f.write(rendered_content)
                    
                    logger.info(f"✓ Archivo generado: {output_file}")

                except TemplateNotFound as e:
                    logger.error(f"✗ Template no encontrado: {e}")
                except Exception as e:
                    logger.error(f"✗ Error renderizando template {template_file}: {e}")

            logger.info(f"\nArchivos de configuración generados en: {output_path.absolute()}")
            return True

        except Exception as e:
            logger.error(f"Error generando archivos de configuración: {e}")
            return False

    def run(self, generate_configs: bool = True) -> bool:
        """
        Ejecuta el proceso completo de carga de configuración.

        Args:
            generate_configs: Si se deben generar archivos de configuración

        Returns:
            True si el proceso fue exitoso
        """
        logger.info("=" * 60)
        logger.info("Iniciando carga de configuración")
        logger.info("=" * 60)

        # Conectar con GitLab
        if not self.connect_gitlab():
            logger.error("No se pudo conectar con GitLab")
            return False

        # Leer Excel
        if not self.read_excel():
            logger.error("No se pudo leer el archivo Excel")
            return False

        # Configurar variables en GitLab
        if not self.set_gitlab_variables():
            logger.error("Error configurando variables en GitLab")
            return False

        # Generar archivos de configuración
        if generate_configs:
            if not self.generate_config_files():
                logger.error("Error generando archivos de configuración")
                return False

        logger.info("=" * 60)
        logger.info("Proceso completado exitosamente")
        logger.info("=" * 60)
        return True


def main():
    """Función principal"""
    # Obtener configuración desde variables de entorno
    gitlab_url = os.getenv('CI_SERVER_URL', 'https://gitlab.com')
    token = os.getenv('GIT_TOKEN')
    project_id = os.getenv('CI_PROJECT_ID')
    excel_path = os.getenv('EXCEL_PATH', 'Project_Master_Config.xlsx')

    # Validar variables requeridas
    if not token:
        logger.error("ERROR: Variable de entorno GIT_TOKEN no está configurada")
        sys.exit(1)

    if not project_id:
        logger.error("ERROR: Variable de entorno CI_PROJECT_ID no está configurada")
        sys.exit(1)

    logger.info(f"Configuración:")
    logger.info(f"  - GitLab URL: {gitlab_url}")
    logger.info(f"  - Project ID: {project_id}")
    logger.info(f"  - Excel Path: {excel_path}")

    # Crear y ejecutar loader
    loader = ConfigLoader(
        excel_path=excel_path,
        gitlab_url=gitlab_url,
        token=token,
        project_id=project_id
    )

    success = loader.run()
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
