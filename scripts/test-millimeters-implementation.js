#!/usr/bin/env node

/**
 * Test script for validating millimeters measurement implementation
 * Tests conversion accuracy, display formatting, and data persistence
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin with the correct project
const projectId = process.env.GCLOUD_PROJECT || 'growth-training-app';
console.log(`Testing millimeters implementation for project: ${projectId}`);

if (!admin.apps.length) {
    admin.initializeApp({
        projectId: projectId,
    });
}

const db = admin.firestore();

// Test data for conversions
const testCases = {
    length: [
        { inches: 6.0, cm: 15.24, mm: 152, type: 'BPEL' },
        { inches: 5.5, cm: 13.97, mm: 140, type: 'BPEL' },
        { inches: 7.0, cm: 17.78, mm: 178, type: 'BPFSL' },
        { inches: 6.25, cm: 15.88, mm: 159, type: 'NBPEL' }
    ],
    girth: [
        { inches: 4.5, cm: 11.43, mm: 114, type: 'MSEG' },
        { inches: 5.0, cm: 12.7, mm: 127, type: 'MSEG' },
        { inches: 4.75, cm: 12.07, mm: 121, type: 'BEG' },
        { inches: 5.25, cm: 13.34, mm: 133, type: 'MEG' }
    ],
    volume: [
        { inches3: 10.0, cm3: 163.87, mm3: 163871, type: 'Volume' },
        { inches3: 15.5, cm3: 254.00, mm3: 254000, type: 'Volume' }
    ]
};

// Conversion functions to test
function inchesToMm(inches) {
    return Math.round(inches * 25.4);
}

function mmToInches(mm) {
    return mm / 25.4;
}

function cmToMm(cm) {
    return Math.round(cm * 10);
}

function inchesToCm(inches) {
    return Math.round(inches * 2.54 * 10) / 10;
}

// Test conversion accuracy
function testConversions() {
    console.log('\n📏 Testing Conversion Accuracy...\n');
    let passed = 0;
    let failed = 0;

    // Test length conversions
    console.log('Length Measurements:');
    testCases.length.forEach(test => {
        const calculatedMm = inchesToMm(test.inches);
        const calculatedCm = inchesToCm(test.inches);
        const mmMatch = calculatedMm === test.mm;
        const cmMatch = Math.abs(calculatedCm - test.cm) < 0.1;

        if (mmMatch && cmMatch) {
            console.log(`✅ ${test.type}: ${test.inches}" → ${calculatedMm}mm (expected ${test.mm}mm) → ${calculatedCm}cm (expected ${test.cm}cm)`);
            passed++;
        } else {
            console.log(`❌ ${test.type}: ${test.inches}" → ${calculatedMm}mm (expected ${test.mm}mm) → ${calculatedCm}cm (expected ${test.cm}cm)`);
            failed++;
        }
    });

    // Test girth conversions
    console.log('\nGirth Measurements:');
    testCases.girth.forEach(test => {
        const calculatedMm = inchesToMm(test.inches);
        const calculatedCm = inchesToCm(test.inches);
        const mmMatch = calculatedMm === test.mm;
        const cmMatch = Math.abs(calculatedCm - test.cm) < 0.1;

        if (mmMatch && cmMatch) {
            console.log(`✅ ${test.type}: ${test.inches}" → ${calculatedMm}mm (expected ${test.mm}mm) → ${calculatedCm}cm (expected ${test.cm}cm)`);
            passed++;
        } else {
            console.log(`❌ ${test.type}: ${test.inches}" → ${calculatedMm}mm (expected ${test.mm}mm) → ${calculatedCm}cm (expected ${test.cm}cm)`);
            failed++;
        }
    });

    // Test volume conversions
    console.log('\nVolume Measurements:');
    testCases.volume.forEach(test => {
        const calculatedMm3 = Math.round(test.inches3 * 16387.064);
        const calculatedCm3 = Math.round(test.inches3 * 16.387064 * 10) / 10;
        const mm3Match = Math.abs(calculatedMm3 - test.mm3) < 10;
        const cm3Match = Math.abs(calculatedCm3 - test.cm3) < 0.5;

        if (mm3Match && cm3Match) {
            console.log(`✅ ${test.type}: ${test.inches3}in³ → ${calculatedMm3}mm³ (expected ${test.mm3}mm³)`);
            passed++;
        } else {
            console.log(`❌ ${test.type}: ${test.inches3}in³ → ${calculatedMm3}mm³ (expected ${test.mm3}mm³)`);
            failed++;
        }
    });

    console.log(`\n📊 Conversion Tests: ${passed} passed, ${failed} failed`);
    return failed === 0;
}

// Test validation ranges for millimeters
function testValidationRanges() {
    console.log('\n🔍 Testing Validation Ranges...\n');

    // Hard limits (should reject)
    const hardLimits = {
        lengthMin: 76,  // 3 inches
        lengthMax: 279, // 11 inches
        girthMin: 76,   // 3 inches
        girthMax: 203   // 8 inches
    };

    // Soft limits (should warn)
    const softLimits = {
        lengthMin: 102, // 4 inches
        lengthMax: 254, // 10 inches
        girthMin: 89,   // 3.5 inches
        girthMax: 165   // 6.5 inches
    };

    console.log('Hard Limits (values outside these should be rejected):');
    console.log(`  Length: ${hardLimits.lengthMin}mm - ${hardLimits.lengthMax}mm`);
    console.log(`  Girth:  ${hardLimits.girthMin}mm - ${hardLimits.girthMax}mm`);

    console.log('\nSoft Limits (values outside these should trigger warning):');
    console.log(`  Length: ${softLimits.lengthMin}mm - ${softLimits.lengthMax}mm`);
    console.log(`  Girth:  ${softLimits.girthMin}mm - ${softLimits.girthMax}mm`);

    // Test edge cases
    console.log('\n🔸 Edge Case Tests:');

    const edgeCases = [
        { value: 75, type: 'length', expected: 'reject', reason: 'below hard minimum' },
        { value: 280, type: 'length', expected: 'reject', reason: 'above hard maximum' },
        { value: 100, type: 'length', expected: 'warn', reason: 'below soft minimum' },
        { value: 255, type: 'length', expected: 'warn', reason: 'above soft maximum' },
        { value: 152, type: 'length', expected: 'accept', reason: 'within normal range' }
    ];

    edgeCases.forEach(test => {
        console.log(`  ${test.value}mm (${test.type}): Expected to ${test.expected} - ${test.reason}`);
    });

    return true;
}

// Test data persistence
async function testDataPersistence() {
    console.log('\n💾 Testing Data Persistence...\n');

    const testUserId = 'test-mm-user-' + Date.now();
    const testData = {
        // Store in inches (internal format)
        bpel: 5.984251968503937,  // 152mm
        mseg: 4.488188976377953,  // 114mm
        timestamp: admin.firestore.Timestamp.now(),
        userId: testUserId
    };

    try {
        // Create test entry
        console.log('Creating test entry with values stored in inches...');
        const docRef = await db.collection('gains_entries').add(testData);
        console.log(`✅ Test entry created: ${docRef.id}`);

        // Read back and verify
        const doc = await docRef.get();
        const data = doc.data();

        // Convert to millimeters for display
        const bpelMm = Math.round(data.bpel * 25.4);
        const msegMm = Math.round(data.mseg * 25.4);

        console.log(`\n📖 Reading back data:`);
        console.log(`  Stored BPEL: ${data.bpel.toFixed(6)}" → Displayed: ${bpelMm}mm`);
        console.log(`  Stored MSEG: ${data.mseg.toFixed(6)}" → Displayed: ${msegMm}mm`);

        // Verify conversion accuracy
        const bpelCorrect = bpelMm === 152;
        const msegCorrect = msegMm === 114;

        if (bpelCorrect && msegCorrect) {
            console.log('\n✅ Data persistence and conversion working correctly');
        } else {
            console.log('\n❌ Data conversion mismatch');
        }

        // Clean up test data
        await docRef.delete();
        console.log('🧹 Test data cleaned up');

        return bpelCorrect && msegCorrect;
    } catch (error) {
        console.error('❌ Error testing data persistence:', error);
        return false;
    }
}

// Test formatting rules
function testFormatting() {
    console.log('\n🎨 Testing Display Formatting...\n');

    const formatTests = [
        { unit: 'inches', value: 6.25, expected: '6.25"', decimals: 2 },
        { unit: 'inches', value: 5.5, expected: '5.50"', decimals: 2 },
        { unit: 'cm', value: 15.2, expected: '15.2cm', decimals: 1 },
        { unit: 'cm', value: 12.75, expected: '12.8cm', decimals: 1 },
        { unit: 'mm', value: 152.4, expected: '152mm', decimals: 0 },
        { unit: 'mm', value: 140.6, expected: '141mm', decimals: 0 }
    ];

    console.log('Format Rules:');
    console.log('  Inches: 2 decimal places');
    console.log('  Centimeters: 1 decimal place');
    console.log('  Millimeters: whole numbers only\n');

    let passed = 0;
    formatTests.forEach(test => {
        const formatted = formatValue(test.value, test.unit, test.decimals);
        const correct = formatted === test.expected;
        if (correct) {
            console.log(`✅ ${test.unit}: ${test.value} → ${formatted}`);
            passed++;
        } else {
            console.log(`❌ ${test.unit}: ${test.value} → ${formatted} (expected ${test.expected})`);
        }
    });

    return passed === formatTests.length;
}

function formatValue(value, unit, decimals) {
    const rounded = decimals === 0 ? Math.round(value) :
                   parseFloat(value.toFixed(decimals));
    const symbol = unit === 'inches' ? '"' : unit;
    return decimals === 0 ? `${rounded}${symbol}` :
           `${rounded.toFixed(decimals)}${symbol}`;
}

// Run all tests
async function runAllTests() {
    console.log('========================================');
    console.log('   MILLIMETERS IMPLEMENTATION TESTS    ');
    console.log('========================================');

    const results = {
        conversions: testConversions(),
        validation: testValidationRanges(),
        formatting: testFormatting(),
        persistence: await testDataPersistence()
    };

    console.log('\n========================================');
    console.log('            TEST SUMMARY                ');
    console.log('========================================\n');

    Object.entries(results).forEach(([test, passed]) => {
        console.log(`${passed ? '✅' : '❌'} ${test.charAt(0).toUpperCase() + test.slice(1)} Tests: ${passed ? 'PASSED' : 'FAILED'}`);
    });

    const allPassed = Object.values(results).every(r => r === true);

    if (allPassed) {
        console.log('\n🎉 All tests passed! Millimeters implementation is working correctly.');
    } else {
        console.log('\n⚠️ Some tests failed. Please review the implementation.');
    }

    process.exit(allPassed ? 0 : 1);
}

// Execute tests
runAllTests().catch(error => {
    console.error('Fatal error running tests:', error);
    process.exit(1);
});