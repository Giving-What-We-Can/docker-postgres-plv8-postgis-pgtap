#!/bin/bash
set -e

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
        -p 5432 \
        ${tag})

        # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL to start..."
    sleep 10

    # Get the mapped port
    port=$(docker port ${container_id} 5432/tcp | cut -d: -f2)

    # Test PostGIS for base image
    if [ "${target}" = "base" ]; then
        echo "Testing PostGIS extension..."
        PGPASSWORD=postgres psql -h localhost -p ${port} -U postgres -d test -c "SELECT PostGIS_Version();"
    fi

    # Test both PostGIS and pgTAP for testing image
    if [ "${target}" = "testing" ]; then
        echo "Testing PostGIS and pgTAP extensions..."
        # Check PostGIS version
        PGPASSWORD=postgres psql -h localhost -p ${port} -U postgres -d test -c "SELECT PostGIS_Version();"

        # Create and verify pgTAP
        PGPASSWORD=postgres psql -h localhost -p ${port} -U postgres -d test -c "CREATE EXTENSION IF NOT EXISTS pgtap;"
        PGPASSWORD=postgres psql -h localhost -p ${port} -U postgres -d test -c "SELECT * FROM pg_extension WHERE extname = 'pgtap';"
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
