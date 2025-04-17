#!/bin/bash

CASSANDRA_CONTAINER="e-commerce_cassandra"

# Création du keyspace et de la table
docker exec -i $CASSANDRA_CONTAINER cqlsh -e "
CREATE KEYSPACE IF NOT EXISTS ecommerce WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
USE ecommerce;
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY,
    name text,
    price float,
    category text,
    description text,
    brand text,
    created_at timestamp
);
"

# Fonction pour insérer un produit
insert_product() {
  ID=$(uuidgen)
  NAME="Product_$RANDOM"
  PRICE=$(awk -v min=10 -v max=500 'BEGIN{srand(); printf "%.2f", min+rand()*(max-min)}')
  CATEGORY="Category_$((RANDOM % 5 + 1))"
  DESCRIPTION="A sample description for $NAME"
  BRAND="Brand_$((RANDOM % 3 + 1))"
  CREATED_AT=$(date +%Y-%m-%dT%H:%M:%S)

  CQL=$(cat <<EOF
USE ecommerce;
INSERT INTO products (id, name, price, category, description, brand, created_at)
VALUES ($ID, '$NAME', $PRICE, '$CATEGORY', '$DESCRIPTION', '$BRAND', toTimestamp(now()));
EOF
)

  echo "$CQL" | docker exec -i $CASSANDRA_CONTAINER cqlsh
}

# Boucle d'insertion
for i in {1..10}; do
  echo "Insertion du produit $i..."
  insert_product
done

echo "✅ Insertion terminée !"

