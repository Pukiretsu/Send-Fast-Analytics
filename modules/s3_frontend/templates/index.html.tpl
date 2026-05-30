<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <title>Serverless Data Lake Orders</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; background: #f7f8fb; }
    main { max-width: 760px; margin: auto; background: white; padding: 24px; border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,.08); }
    input, button { padding: 10px; margin: 6px 0; width: 100%; box-sizing: border-box; }
    button { cursor: pointer; }
    pre { background: #111827; color: #e5e7eb; padding: 16px; border-radius: 8px; overflow: auto; }
  </style>
</head>
<body>
  <main>
    <h1>Orders Data Lake</h1>
    <p>Formulario de prueba para enviar órdenes al endpoint serverless.</p>
    <button onclick="sendOrder()">Enviar orden de prueba</button>
    <pre id="output"></pre>
  </main>
  <script>
    async function sendOrder() {
      const payload = {
        order_id: crypto.randomUUID(),
        timestamp: new Date().toISOString(),
        ciudad_zona: "Bogota-Norte",
        estado_pedido: "CREADO",
        monto: 125000,
        tiempo_entrega: 45
      };

      const res = await fetch("${api_url}", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      document.getElementById("output").textContent = JSON.stringify({
        status: res.status,
        response: await res.text(),
        payload
      }, null, 2);
    }
  </script>
</body>
</html>
