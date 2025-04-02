router.post('/', async (req, res) => {
    const { user_id, customer_id, total, earned_points, products } = req.body;

    if (!user_id || !customer_id || !products.length) {
        return res.status(400).json({ error: "Datos incompletos." });
    }

    try {
        await db.promise().beginTransaction();

        // Insertar la venta principal
        const [ventaResult] = await db.promise().query(
            "INSERT INTO ventas (user_id, customer_id, total, earned_points) VALUES (?, ?, ?, ?)",
            [user_id, customer_id, total, earned_points]
        );
        const sale_id = ventaResult.insertId;

        let totalEarnedPoints = 0; // Para recalcular el total de puntos

        // Procesar cada producto
        for (const product of products) {
            // Consultar el stock actual del producto
            const [stockResult] = await db.promise().query(
                "SELECT quantity FROM productos WHERE id = ?",
                [product.product_id]
            );

            if (!stockResult.length) {
                await db.promise().rollback();
                return res.status(400).json({ error: `Producto con ID ${product.product_id} no encontrado.` });
            }

            const stockDisponible = stockResult[0].quantity;

            // Verificar si hay suficiente stock
            if (product.quantity > stockDisponible) {
                await db.promise().rollback();
                return res.status(400).json({ error: `Stock insuficiente para el producto ${product.product_id}. Disponible: ${stockDisponible}, solicitado: ${product.quantity}.` });
            }

            // Calcular puntos por cada producto (1 punto por cada 30 LPS en el subtotal)
            const productEarnedPoints = Math.floor(product.subtotal / 30);
            totalEarnedPoints += productEarnedPoints;

            // Insertar el detalle de la venta
            await db.promise().query(
                "INSERT INTO ventas_detalle (sale_id, product_id, quantity, subtotal, earned_points) VALUES (?, ?, ?, ?, ?)",
                [sale_id, product.product_id, product.quantity, product.subtotal, productEarnedPoints]
            );

            // Actualizar el stock del producto
            await db.promise().query(
                "UPDATE productos SET quantity = quantity - ? WHERE id = ?",
                [product.quantity, product.product_id]
            );
        }

        // Actualizar los puntos ganados en la tabla `ventas`
        await db.promise().query(
            "UPDATE ventas SET earned_points = ? WHERE id = ?",
            [totalEarnedPoints, sale_id]
        );

        // Registrar los puntos en historial_puntos si aplica
        if (totalEarnedPoints > 0) {
            await db.promise().query(
                "INSERT INTO historial_puntos (customer_id, sale_id, points, type) VALUES (?, ?, ?, 'earned')",
                [customer_id, sale_id, totalEarnedPoints]
            );

            // Actualizar los puntos acumulados del cliente
            await db.promise().query(
                "UPDATE clientes SET accumulated_points = accumulated_points + ? WHERE id = ?",
                [totalEarnedPoints, customer_id]
            );
        }

        await db.promise().commit();
        res.json({ message: "Venta registrada con éxito" });
    } catch (error) {
        await db.promise().rollback();
        console.error("Error en el registro de venta:", error);
        res.status(500).json({ error: "Error al registrar la venta" });
    }
});
