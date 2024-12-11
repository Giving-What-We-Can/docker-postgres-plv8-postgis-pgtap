#!/bin/bash
set -e

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    local host=$1
    local port=$2
    local user=$3
    local max_attempts=30
    local attempt=1

    echo "Waiting for PostgreSQL to become available..."
    
    while [ $attempt -le $max_attempts ]; do
        PGPASSWORD=postgres psql -h "$host" -p "$port" -U "$user" -d "test" -c "SELECT 1;" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "PostgreSQL is ready!"
            return 0
        fi
        
        echo "Attempt $attempt of $max_attempts: PostgreSQL is not ready yet..."
        sleep 1
        attempt=$((attempt + 1))
    done

    echo "Failed to connect to PostgreSQL after $max_attempts attempts"
    return 1
}

# Function to test a container
test_container() {
    local target=$1
    local tag="postgres-test-${target}"
    echo "Testing ${target} image..."
    
    # Build the image
    docker build --target ${target} -t ${tag} .
    
    # Run the container
    container_id=$(docker run -d \
        -e POSTGRES_PASSWORD=postgres \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_DB=test \
        -e POSTGIS_SCHEMA=postgis \
        -p 5433:5432 \
        ${tag})

    # Wait for PostgreSQL to be ready
    if ! wait_for_postgres "localhost" "5433" "postgres"; then
        echo "Failed to start PostgreSQL"
        docker logs ${container_id}
        docker stop ${container_id}
        docker rm ${container_id}
        exit 1
    fi
    
    echo "Verifying PostGIS installation..."
    export PGPASSWORD=postgres
    # Check extension location
    psql -h localhost -p 5433 -U postgres -d test -c "
        SELECT n.nspname as schema_name, e.extname as extension
        FROM pg_extension e
        JOIN pg_namespace n ON n.oid = e.extnamespace
        WHERE e.extname LIKE 'postgis%';"

    # Test PostGIS functionality
    psql -h localhost -p 5433 -U postgres -d test -c "SELECT postgis.PostGIS_Full_Version();"
    
    # Test pgTAP for testing image
    if [ "${target}" = "testing" ]; then
        echo "Testing pgTAP installation..."
        psql -h localhost -p 5433 -U postgres -d test -c "CREATE EXTENSION IF NOT EXISTS pgtap;"
        psql -h localhost -p 5433 -U postgres -d test -c "SELECT * FROM pg_extension WHERE extname = 'pgtap';"
    fi
    
    # Clean up
    docker stop ${container_id}
    docker rm ${container_id}
    echo "Test completed for ${target} image"
    echo "----------------------------------------"
}

# Test both images
test_container "base"
test_container "testing"