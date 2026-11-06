/* =====================================================================
   DistriMax - 04 Vistas (usadas por reportes y dashboard)
   ===================================================================== */
USE DistriMaxDB;
GO

-- Edades calculadas sobre días vencidos (desde FechaVencimiento)
CREATE VIEW vw_CarteraEdades
AS
SELECT c.IdCliente, c.NumeroDocumento, c.RazonSocial, c.IdVendedor, u.Nombre AS Vendedor,
       SUM(CASE WHEN DATEDIFF(DAY, f.FechaVencimiento, GETDATE()) <= 30 THEN f.Saldo ELSE 0 END) AS Rango_0_30,
       SUM(CASE WHEN DATEDIFF(DAY, f.FechaVencimiento, GETDATE()) BETWEEN 31 AND 60 THEN f.Saldo ELSE 0 END) AS Rango_31_60,
       SUM(CASE WHEN DATEDIFF(DAY, f.FechaVencimiento, GETDATE()) BETWEEN 61 AND 90 THEN f.Saldo ELSE 0 END) AS Rango_61_90,
       SUM(CASE WHEN DATEDIFF(DAY, f.FechaVencimiento, GETDATE()) > 90 THEN f.Saldo ELSE 0 END) AS Rango_Mas_90,
       SUM(f.Saldo) AS SaldoTotal
FROM Facturas f
INNER JOIN Clientes c ON c.IdCliente = f.IdCliente
LEFT JOIN Usuarios u ON u.IdUsuario = c.IdVendedor
WHERE f.Estado = 'ACTIVA' AND f.Saldo > 0
GROUP BY c.IdCliente, c.NumeroDocumento, c.RazonSocial, c.IdVendedor, u.Nombre;
GO

CREATE VIEW vw_InventarioValorizado
AS
SELECT b.IdBodega, b.Nombre AS Bodega, p.IdProducto, p.Codigo, p.Nombre AS Producto, c.Nombre AS Categoria,
       p.Unidad, i.Cantidad, i.CantidadReservada, p.CostoPromedio,
       i.Cantidad * p.CostoPromedio AS ValorInventario
FROM Inventario i
INNER JOIN Bodegas b ON b.IdBodega = i.IdBodega
INNER JOIN Productos p ON p.IdProducto = i.IdProducto
INNER JOIN Categorias c ON c.IdCategoria = p.IdCategoria;
GO

CREATE VIEW vw_VentasPorVendedor
AS
SELECT f.IdVendedor, u.Nombre AS Vendedor, YEAR(f.Fecha) AS Anio, MONTH(f.Fecha) AS Mes,
       COUNT(*) AS NumFacturas, SUM(f.BaseIva) AS VentaNeta, SUM(f.Total) AS TotalFacturado
FROM Facturas f
LEFT JOIN Usuarios u ON u.IdUsuario = f.IdVendedor
WHERE f.Estado = 'ACTIVA'
GROUP BY f.IdVendedor, u.Nombre, YEAR(f.Fecha), MONTH(f.Fecha);
GO

PRINT 'Vistas creadas';
GO
