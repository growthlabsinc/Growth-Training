#!/bin/bash

# Script to analyze and remove single-step methods from Firestore using Firebase CLI
# This will preserve ADS methods regardless of step count

echo "🔥 Single-Step Method Removal Tool"
echo "=================================="
echo ""
echo "This script will help remove all single-step methods from growth_exercises"
echo "except for ADS (All Day Stretching) methods."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI is not installed${NC}"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Login check
echo "Checking Firebase authentication..."
firebase projects:list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Please login to Firebase:${NC}"
    firebase login
fi

# Select project
echo -e "\n${BLUE}Using project: growth-training-app${NC}"
firebase use growth-training-app

# Create a Node.js script to run via Firebase
cat > /tmp/analyze-methods.js << 'EOF'
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function analyzeAndRemove() {
    const action = process.argv[2] || 'analyze';
    console.log(`\n🔍 ${action === 'delete' ? 'DELETING' : 'ANALYZING'} methods...\n`);

    try {
        const snapshot = await db.collection('growth_exercises').get();

        if (snapshot.empty) {
            console.log('❌ No methods found in growth_exercises collection');
            return;
        }

        console.log(`📊 Found ${snapshot.size} total methods\n`);

        const toDelete = [];
        const toKeep = [];

        snapshot.forEach(doc => {
            const data = doc.data();
            const id = doc.id;
            const title = data.title || 'Untitled';
            const steps = data.steps || [];

            // Check if this is ADS
            const isADS = id.toLowerCase().includes('ads') ||
                         title.toLowerCase().includes('ads') ||
                         title.toLowerCase().includes('all day') ||
                         title.toLowerCase().includes('all-day');

            // Single step and not ADS = delete
            if (steps.length <= 1 && !isADS) {
                toDelete.push({ id, title, steps: steps.length });
            } else {
                const reason = isADS ? 'ADS method' : `${steps.length} steps`;
                toKeep.push({ id, title, reason });
            }
        });

        // Show results
        console.log('✅ Methods to KEEP:');
        console.log('─'.repeat(50));
        toKeep.forEach(m => {
            console.log(`  • ${m.title} (${m.reason})`);
        });

        console.log('\n🗑️  Methods to DELETE (single-step):');
        console.log('─'.repeat(50));
        if (toDelete.length === 0) {
            console.log('  None - all methods have multiple steps or are ADS');
        } else {
            toDelete.forEach(m => {
                console.log(`  • ${m.title} (${m.steps} step${m.steps === 1 ? '' : 's'})`);
            });
        }

        console.log('\n' + '═'.repeat(50));
        console.log(`Summary: ${toDelete.length} to delete, ${toKeep.length} to keep`);

        // If delete mode, perform deletion
        if (action === 'delete' && toDelete.length > 0) {
            console.log('\n🔥 Deleting single-step methods...');

            const batch = db.batch();
            toDelete.forEach(method => {
                batch.delete(db.collection('growth_exercises').doc(method.id));
            });

            await batch.commit();
            console.log(`✅ Successfully deleted ${toDelete.length} methods`);
        }

    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

analyzeAndRemove().then(() => process.exit(0));
EOF

# Function to run analysis
analyze_methods() {
    echo -e "${BLUE}Running analysis...${NC}"
    echo ""
    cp /tmp/analyze-methods.js functions/analyze-methods-temp.js
    cd functions && node analyze-methods-temp.js analyze
    rm -f analyze-methods-temp.js
}

# Function to delete methods
delete_methods() {
    echo -e "${RED}⚠️  WARNING: This will permanently delete single-step methods!${NC}"
    echo -e "${RED}This action cannot be undone.${NC}"
    echo ""
    read -p "Type 'DELETE' to confirm deletion: " confirm

    if [ "$confirm" == "DELETE" ]; then
        echo ""
        cp /tmp/analyze-methods.js functions/analyze-methods-temp.js
        cd functions && node analyze-methods-temp.js delete
        rm -f analyze-methods-temp.js
        echo ""
        echo -e "${GREEN}✅ Deletion complete!${NC}"
    else
        echo -e "${YELLOW}Deletion cancelled.${NC}"
    fi
}

# Main menu
echo -e "${YELLOW}What would you like to do?${NC}"
echo "1) Analyze methods (dry run - no changes)"
echo "2) Delete single-step methods (except ADS)"
echo "3) Exit"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        analyze_methods
        ;;
    2)
        # First show analysis
        analyze_methods
        echo ""
        # Then ask for confirmation
        delete_methods
        ;;
    3)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Clean up
rm -f /tmp/analyze-methods.js