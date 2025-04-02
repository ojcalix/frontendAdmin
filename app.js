// Ruta para cargar las ventas
app.get('/ventas', async (req, res) => {
    try {
        const query = `
            SELECT 
                v.id AS venta_id,
                v.user_id,
                v.cliente_id,
                vd.product_id,
                vd.cantidad,
                v.total,
                v.puntos_ganados,
                v.sale_date
            FROM 
                ventas v
            JOIN 
                ventas_detalle vd ON v.id = vd.venta_id
        `;

        const [ventas] = await db.promise().query(query);
        res.json(ventas);
    } catch (error) {
        console.error("Error al cargar las ventas:", error);
        res.status(500).json({ error: "Error al cargar las ventas" });
    }
});