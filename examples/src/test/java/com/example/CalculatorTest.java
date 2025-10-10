package com.example;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for Calculator class
 */
class CalculatorTest {
    
    private Calculator calculator;
    
    @BeforeEach
    void setUp() {
        calculator = new Calculator();
    }
    
    @Test
    void testAdd() {
        assertEquals(5, calculator.add(2, 3));
        assertEquals(0, calculator.add(-1, 1));
        assertEquals(-5, calculator.add(-2, -3));
    }
    
    @Test
    void testSubtract() {
        assertEquals(1, calculator.subtract(3, 2));
        assertEquals(-2, calculator.subtract(-1, 1));
        assertEquals(1, calculator.subtract(-2, -3));
    }
    
    @Test
    void testMultiply() {
        assertEquals(6, calculator.multiply(2, 3));
        assertEquals(-6, calculator.multiply(-2, 3));
        assertEquals(6, calculator.multiply(-2, -3));
    }
    
    @Test
    void testDivide() {
        assertEquals(2.0, calculator.divide(6, 3));
        assertEquals(-2.0, calculator.divide(-6, 3));
        assertEquals(2.5, calculator.divide(5, 2));
    }
    
    @Test
    void testDivideByZero() {
        assertThrows(ArithmeticException.class, () -> {
            calculator.divide(5, 0);
        });
    }
}
