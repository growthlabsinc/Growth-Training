#!/usr/bin/env python3
"""
Firebase Migration Script: Angion Method to PE Methods
Migrates existing Angion Method data to PE exercise data in Firebase
"""

import json
import sys
from datetime import datetime
from pathlib import Path

def load_mapping():
    """Load the Angion to PE mapping configuration"""
    mapping_file = Path('angion_to_pe_mapping.json')

    if not mapping_file.exists():
        print("❌ Mapping file not found: angion_to_pe_mapping.json")
        return None

    with open(mapping_file, 'r') as f:
        return json.load(f)

def load_pe_database():
    """Load the enhanced PE exercise database"""
    db_file = Path('extracted_data/pe_methods_database_enhanced.json')

    if not db_file.exists():
        print("❌ PE database not found: extracted_data/pe_methods_database_enhanced.json")
        return None

    with open(db_file, 'r') as f:
        return json.load(f)

def generate_migration_script(mapping, pe_database):
    """Generate Firebase migration JavaScript"""

    migration_js = """// Firebase Migration Script: Angion to PE Methods
// Generated: {timestamp}
// WARNING: Backup your database before running this migration!

const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

// Initialize Firebase Admin
admin.initializeApp({{
  credential: admin.credential.cert(serviceAccount)
}});

const db = admin.firestore();
const batch = db.batch();

// Exercise mappings
const exerciseMappings = {mappings};

// PE exercises to add
const peExercises = {exercises};

// Text replacements
const textReplacements = {text_replacements};

async function migrateExercises() {
  console.log('🚀 Starting Angion to PE migration...');

  // Step 1: Backup existing methods
  console.log('📦 Backing up existing methods...');
  const methodsSnapshot = await db.collection('growth_methods').get();
  const backup = [];

  methodsSnapshot.forEach(doc => {
    backup.push({
      id: doc.id,
      data: doc.data()
    });
  });

  // Save backup
  await db.collection('migration_backups').doc(`backup_${{Date.now()}}`).set({
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    data: backup,
    type: 'angion_to_pe_migration'
  });

  console.log(`✅ Backed up ${{backup.length}} methods`);

  // Step 2: Add PE exercises
  console.log('➕ Adding PE exercises...');
  for (const exercise of peExercises) {
    const docRef = db.collection('growth_methods').doc(exercise.id);
    batch.set(docRef, {
      ...exercise,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      migrated: true,
      migrationDate: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  // Step 3: Update user routines
  console.log('🔄 Updating user routines...');
  const routinesSnapshot = await db.collection('routines').get();

  for (const doc of routinesSnapshot.docs) {
    const routine = doc.data();
    let updated = false;

    // Update exercise IDs
    if (routine.exercises && Array.isArray(routine.exercises)) {
      const newExercises = routine.exercises.map(exerciseId => {
        if (exerciseMappings[exerciseId]) {
          updated = true;
          return exerciseMappings[exerciseId].new_id;
        }
        return exerciseId;
      });

      if (updated) {
        batch.update(doc.ref, {
          exercises: newExercises,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          migrated: true
        });
      }
    }
  }

  // Step 4: Update user progress
  console.log('📊 Migrating user progress...');
  const sessionsSnapshot = await db.collection('session_logs').get();

  for (const doc of sessionsSnapshot.docs) {
    const session = doc.data();
    let updated = false;

    // Update method ID if it's an Angion method
    if (session.methodId && exerciseMappings[session.methodId]) {
      batch.update(doc.ref, {
        methodId: exerciseMappings[session.methodId].new_id,
        originalMethodId: session.methodId,
        migrated: true,
        migratedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      updated = true;
    }
  }

  // Step 5: Update educational content
  console.log('📚 Updating educational content...');
  const articlesSnapshot = await db.collection('educational_resources').get();

  for (const doc of articlesSnapshot.docs) {
    const article = doc.data();
    let content = article.content || '';
    let title = article.title || '';
    let updated = false;

    // Apply text replacements
    for (const replacement of textReplacements) {
      const regex = new RegExp(replacement.old, 'gi');
      if (regex.test(content)) {
        content = content.replace(regex, replacement.new);
        updated = true;
      }
      if (regex.test(title)) {
        title = title.replace(regex, replacement.new);
        updated = true;
      }
    }

    if (updated) {
      batch.update(doc.ref, {
        content: content,
        title: title,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        migrated: true
      });
    }
  }

  // Commit the batch
  console.log('💾 Committing changes...');
  await batch.commit();

  console.log('✅ Migration completed successfully!');

  // Generate migration report
  const report = {
    timestamp: new Date().toISOString(),
    methodsAdded: peExercises.length,
    routinesUpdated: routinesSnapshot.size,
    sessionsUpdated: sessionsSnapshot.size,
    articlesUpdated: articlesSnapshot.size
  };

  await db.collection('migration_reports').add(report);
  console.log('📊 Migration Report:', report);
}

// Rollback function
async function rollbackMigration(backupId) {
  console.log('⏮️ Rolling back migration...');

  const backup = await db.collection('migration_backups').doc(backupId).get();
  if (!backup.exists) {
    console.error('❌ Backup not found:', backupId);
    return;
  }

  const backupData = backup.data();
  const batch = db.batch();

  // Restore methods
  for (const item of backupData.data) {
    const docRef = db.collection('growth_methods').doc(item.id);
    batch.set(docRef, item.data);
  }

  await batch.commit();
  console.log('✅ Rollback completed');
}

// Execute migration
if (process.argv[2] === 'rollback') {
  const backupId = process.argv[3];
  if (!backupId) {
    console.error('❌ Please provide backup ID for rollback');
    process.exit(1);
  }
  rollbackMigration(backupId).catch(console.error);
} else {
  migrateExercises()
    .then(() => {
      console.log('🎉 Migration completed successfully!');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Migration failed:', error);
      process.exit(1);
    });
}
""".format(
        timestamp=datetime.now().isoformat(),
        mappings=json.dumps(mapping['exercise_mappings'], indent=2),
        exercises=json.dumps(pe_database['exercises'][:10], indent=2),  # Top 10 exercises for initial migration
        text_replacements=json.dumps(mapping['text_replacements'], indent=2)
    )

    return migration_js

def main():
    """Generate Firebase migration script"""
    print("🔧 Generating Firebase Migration Script")
    print("=" * 50)

    # Load mapping
    print("\n📚 Loading mapping configuration...")
    mapping = load_mapping()
    if not mapping:
        return False
    print(f"   Loaded {len(mapping['exercise_mappings'])} mappings")

    # Load PE database
    print("\n🗄️ Loading PE exercise database...")
    pe_database = load_pe_database()
    if not pe_database:
        return False
    print(f"   Loaded {len(pe_database['exercises'])} exercises")

    # Generate migration script
    print("\n✍️ Generating migration script...")
    migration_script = generate_migration_script(mapping, pe_database)

    # Save migration script
    output_file = Path('firebase_migrate_angion_to_pe.js')
    with open(output_file, 'w') as f:
        f.write(migration_script)

    print(f"\n✅ Migration script saved to: {output_file}")

    # Generate instructions
    instructions = """

MIGRATION INSTRUCTIONS
======================

1. BACKUP YOUR DATABASE FIRST!
   - Export Firestore data from Firebase Console
   - Save a copy of all collections

2. Install dependencies:
   npm install firebase-admin

3. Get service account key:
   - Go to Firebase Console > Project Settings > Service Accounts
   - Generate new private key
   - Save as 'service-account-key.json' in scripts directory

4. Test migration in development:
   node firebase_migrate_angion_to_pe.js

5. Review migration report in Firebase Console

6. If issues occur, rollback:
   node firebase_migrate_angion_to_pe.js rollback <backup_id>

7. Once verified, run in production

IMPORTANT: This migration will:
- Add PE exercises to growth_methods collection
- Update user routines to use new exercise IDs
- Migrate session logs to reference PE exercises
- Update educational content text

Always test in development environment first!
"""

    print(instructions)

    # Save instructions
    instructions_file = Path('MIGRATION_INSTRUCTIONS.txt')
    with open(instructions_file, 'w') as f:
        f.write(instructions)

    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)