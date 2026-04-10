#!/bin/bash

# HelaService Firebase Emulators Script
# Usage: ./scripts/emulators.sh [start|stop|export|import]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

COMMAND=${1:-start}
EXPORT_DIR="./emulator-data"

case $COMMAND in
    start)
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}  Starting Firebase Emulators          ${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo ""
        
        # Create export directory if it doesn't exist
        mkdir -p $EXPORT_DIR
        
        # Import data if exists
        IMPORT_FLAG=""
        if [ -d "$EXPORT_DIR/firestore_export" ]; then
            echo -e "${YELLOW}Found existing emulator data. Importing...${NC}"
            IMPORT_FLAG="--import=$EXPORT_DIR"
        fi
        
        echo -e "${GREEN}Emulators starting on:${NC}"
        echo "  Auth:      http://localhost:9099"
        echo "  Firestore: http://localhost:8080"
        echo "  Functions: http://localhost:5001"
        echo "  Storage:   http://localhost:9199"
        echo "  UI:        http://localhost:4000"
        echo ""
        echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
        echo ""
        
        firebase emulators:start $IMPORT_FLAG \
            --only auth,functions,firestore,storage
        ;;
        
    stop)
        echo -e "${YELLOW}Stopping Firebase Emulators...${NC}"
        pkill -f "firebase emulators" || true
        echo -e "${GREEN}✓ Emulators stopped${NC}"
        ;;
        
    export)
        echo -e "${BLUE}Exporting Emulator Data...${NC}"
        mkdir -p $EXPORT_DIR
        
        # This needs to be run while emulators are running
        curl -X POST \
            http://localhost:8080/emulator/v1/projects/helaservice-prod:export \
            -d "{\"database\": \"projects/helaservice-prod/databases/(default)\", \"export_directory\": \"$EXPORT_DIR\"}" \
            2>/dev/null || {
                echo -e "${RED}Error: Emulators must be running to export data${NC}"
                echo "Run: ./scripts/emulators.sh start"
                exit 1
            }
        
        echo -e "${GREEN}✓ Data exported to $EXPORT_DIR${NC}"
        ;;
        
    import)
        echo -e "${BLUE}Importing Emulator Data...${NC}"
        
        if [ ! -d "$EXPORT_DIR/firestore_export" ]; then
            echo -e "${RED}Error: No export data found in $EXPORT_DIR${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ Data ready to import${NC}"
        echo "Start emulators with: ./scripts/emulators.sh start"
        ;;
        
    seed)
        echo -e "${BLUE}Seeding Emulator with Test Data...${NC}"
        
        # Run seeding script if it exists
        if [ -f "scripts/seed-emulator.ts" ]; then
            cd functions
            npx ts-node ../scripts/seed-emulator.ts
            cd ..
        else
            echo -e "${YELLOW}No seed script found. Creating sample data...${NC}"
            
            # Create sample data using curl
            curl -X POST http://localhost:8080/v1/projects/helaservice-prod/databases/(default)/documents/workers \
                -H "Content-Type: application/json" \
                -d '{
                    "fields": {
                        "fullName": {"stringValue": "Test Worker"},
                        "nic": {"stringValue": "853202937V"},
                        "status": {"stringValue": "approved"},
                        "isOnline": {"booleanValue": true}
                    }
                }' 2>/dev/null || echo "Emulators not running"
        fi
        
        echo -e "${GREEN}✓ Test data seeded${NC}"
        ;;
        
    *)
        echo "Usage: ./scripts/emulators.sh [start|stop|export|import|seed]"
        echo ""
        echo "Commands:"
        echo "  start  - Start Firebase emulators (with auto-import)"
        echo "  stop   - Stop all emulators"
        echo "  export - Export current emulator data (emulators must be running)"
        echo "  import - Prepare to import saved data"
        echo "  seed   - Seed emulators with test data"
        echo ""
        echo "Emulator URLs:"
        echo "  UI:        http://localhost:4000"
        echo "  Auth:      http://localhost:9099"
        echo "  Firestore: http://localhost:8080"
        echo "  Functions: http://localhost:5001"
        echo "  Storage:   http://localhost:9199"
        exit 1
        ;;
esac
