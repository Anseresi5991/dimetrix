/* =====================================================================
   DistriMax - Verificación rápida después de cargar la BD (opcional)
   Todas las consultas de "inconsistencias" deberían devolver 0 filas.
   ===================================================================== */
USE DistriMaxDB;
GO

SELECT 'Usuarios' AS Tabla, COUNT(*) AS Filas FROM Usuarios UNION ALL
SELECT 'Clientes', COUNT(*) FROM Clientes UNION ALL
SELECT 'Proveedor', COUNT(*) FROM Proveedor UNION ALL
SELECT 'Productos', COUNT(*) FROM Productos UNION ALL
SELECT 'Inventario', COUNT(*) FROM Inventario UNION ALL
SELECT 'Kardex', COUNT(*) FROM Kardex UNION ALL
SELECT 'OrdenesCompra', COUNT(*) FROM OrdenesCompra UNION ALL
SELECT 'Pedidos', COUNT(*) FROM Pedidos UNION ALL
SELECT 'Facturas', COUNT(*) FROM Facturas UNION ALL
SELECT 'Abonos', COUNT(*) FROM Abonos;

-- Inconsistencia 1: el último saldo del kardex no coincide con el inventario
;WITH ultimo AS (
    SELECT IdBodega, IdProducto, SaldoCantidad,
           ROW_NUMBER() OVER (PARTITION BY IdBodega, IdProducto ORDER BY Fecha DESC, IdKardex DESC) AS rn
    FROM Kardex
)
SELECT u.IdBodega, u.IdProducto, u.SaldoCantidad, i.Cantidad
FROM ultimo u
INNER JOIN Inventario i ON i.IdBodega = u.IdBodega AND i.IdProducto = u.IdProducto
WHERE u.rn = 1 AND u.SaldoCantidad <> i.Cantidad;

-- Inconsistencia 2: saldo de factura distinto a Total - abonos
SELECT f.IdFactura, f.Total, f.Saldo, ISNULL(SUM(ad.ValorAplicado), 0) AS Abonado
FROM Facturas f
LEFT JOIN AbonosDetalle ad ON ad.IdFactura = f.IdFactura
WHERE f.Estado = 'ACTIVA'
GROUP BY f.IdFactura, f.Total, f.Saldo
HAVING f.Total - ISNULL(SUM(ad.ValorAplicado), 0) <> f.Saldo;

-- Inconsistencia 3: inventario negativo o reservado mayor que existencias
SELECT * FROM Inventario WHERE Cantidad < 0 OR CantidadReservada > Cantidad;

-- Login de prueba: debe devolver 1 fila (admin / admin123)
EXEC sp_Login @Login = 'admin', @Password = '0192023a7bbd73250516f069df18b500';
GO
