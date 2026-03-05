from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({'service': 'product-service', 'status': 'ok'})

@app.route('/products')
def get_products():
    return jsonify([
        {'id': 10, 'name': 'Laptop', 'price': 999.99, 'stock': 50},
        {'id': 11, 'name': 'Mouse', 'price': 29.99, 'stock': 200},
        {'id': 12, 'name': 'Keyboard', 'price': 79.99, 'stock': 150}
    ])

@app.route('/products/<int:product_id>')
def get_product(product_id):
    return jsonify({'id': product_id, 'name': 'Laptop', 'price': 999.99, 'stock': 50})

@app.route('/products', methods=['POST'])
def create_product():
    data = request.get_json()
    return jsonify({'id': 13, **data, 'created_at': 'now'}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
