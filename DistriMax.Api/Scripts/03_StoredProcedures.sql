/* =====================================================================
   DistriMax - 03 Stored Procedures
   Mezcla deliberada: algunos SPs tienen la lógica de negocio completa
   (AP-12), otros son CRUD simples, y varios módulos ni siquiera usan SPs.
   Los detalles de documentos llegan como XML (estilo de la época):
   <items><item idProducto="1" cantidad="10" ... /></items>
   ===================================================================== */
USE DistriMaxDB;
GO

/* ============================== GENERAL ============================== */
CREATE PROCEDURE sp_Consecutivo_Siguiente
    @Tipo    VARCHAR(5),
    @Numero  INT OUTPUT,
    @Prefijo VARCHAR(10) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    -- AP-17: lectura y actualización separadas, sin UPDLOCK/HOLDLOCK.
    -- Con dos usuarios concurrentes pueden salir números repetidos.
    SELECT @Numero = Actual + 1, @Prefijo = Prefijo FROM Consecutivos WHERE Tipo = @Tipo;
    UPDATE Consecutivos SET Actual = @Numero WHERE Tipo = @Tipo;
END
GO

CREATE PROCEDURE sp_Log_Insertar
    @IdUsuario INT,
    @Modulo    NVARCHAR(50),
    @Accion    NVARCHAR(100),
    @Detalle   NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO LogSistema (Fecha, IdUsuario, Modulo, Accion, Detalle)
    VALUES (GETDATE(), @IdUsuario, @Modulo, @Accion, @Detalle);
END
GO

/* ============================= SEGURIDAD ============================= */
CREATE PROCEDURE sp_Login
    @Login    NVARCHAR(50),
    @Password VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.IdUsuario, u.Login, u.Nombre, u.Email, u.IdRol, r.Nombre AS Rol
    FROM Usuarios u
    INNER JOIN Roles r ON r.IdRol = u.IdRol
    WHERE u.Login = @Login AND u.Password = @Password AND u.Activo = 1;
END
GO

CREATE PROCEDURE sp_Usuarios_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.IdUsuario, u.Login, u.Nombre, u.Email, u.IdRol, r.Nombre AS Rol,
           u.Activo, u.UltimoAcceso, u.FechaCreacion
    FROM Usuarios u
    INNER JOIN Roles r ON r.IdRol = u.IdRol
    ORDER BY u.Nombre;
END
GO

CREATE PROCEDURE sp_Usuarios_Guardar
    @IdUsuario INT,
    @Login     NVARCHAR(50),
    @Password  VARCHAR(32) = NULL,
    @Nombre    NVARCHAR(100),
    @Email     NVARCHAR(100) = NULL,
    @IdRol     INT,
    @Activo    BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Usuarios WHERE Login = @Login AND IdUsuario <> @IdUsuario)
    BEGIN
        RAISERROR('Ya existe un usuario con ese login', 16, 1);
        RETURN;
    END

    IF @IdUsuario = 0
    BEGIN
        IF @Password IS NULL
        BEGIN
            RAISERROR('La contraseña es obligatoria para usuarios nuevos', 16, 1);
            RETURN;
        END

        INSERT INTO Usuarios (Login, Password, Nombre, Email, IdRol, Activo, FechaCreacion)
        VALUES (@Login, @Password, @Nombre, @Email, @IdRol, @Activo, GETDATE());

        SET @IdUsuario = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE Usuarios
        SET Login = @Login,
            Nombre = @Nombre,
            Email = @Email,
            IdRol = @IdRol,
            Activo = @Activo,
            Password = ISNULL(@Password, Password)
        WHERE IdUsuario = @IdUsuario;
    END

    SELECT @IdUsuario AS IdUsuario;
END
GO

CREATE PROCEDURE sp_Usuarios_CambiarPassword
    @IdUsuario INT,
    @Password  VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Usuarios SET Password = @Password, Token = NULL, TokenExpira = NULL WHERE IdUsuario = @IdUsuario;
    SELECT @@ROWCOUNT AS Filas;
END
GO

/* ============================== CLIENTES ============================== */
CREATE PROCEDURE sp_Clientes_Listar
    @Buscar NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.IdCliente, c.TipoDocumento, c.NumeroDocumento, c.DV, c.RazonSocial, c.NombreComercial,
           c.Direccion, c.IdCiudad, ci.Nombre AS Ciudad, ci.IdDepartamento, d.Nombre AS Departamento,
           c.Telefono, c.Email, c.CupoCredito, c.DiasCredito, c.IdLista, lp.Nombre AS ListaPrecios,
           c.IdVendedor, u.Nombre AS Vendedor, c.Bloqueado, c.MotivoBloqueo, c.Activo, c.FechaCreacion,
           ISNULL((SELECT SUM(f.Saldo) FROM Facturas f WHERE f.IdCliente = c.IdCliente AND f.Estado = 'ACTIVA'), 0) AS Saldo
    FROM Clientes c
    LEFT JOIN Ciudades ci ON ci.IdCiudad = c.IdCiudad
    LEFT JOIN Departamentos d ON d.IdDepartamento = ci.IdDepartamento
    LEFT JOIN ListasPrecios lp ON lp.IdLista = c.IdLista
    LEFT JOIN Usuarios u ON u.IdUsuario = c.IdVendedor
    WHERE @Buscar IS NULL
       OR c.RazonSocial LIKE '%' + @Buscar + '%'
       OR c.NombreComercial LIKE '%' + @Buscar + '%'
       OR c.NumeroDocumento LIKE '%' + @Buscar + '%'
    ORDER BY c.RazonSocial;
END
GO

-- AP: copia del SELECT de sp_Clientes_Listar con otro WHERE
CREATE PROCEDURE sp_Clientes_Obtener
    @IdCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.IdCliente, c.TipoDocumento, c.NumeroDocumento, c.DV, c.RazonSocial, c.NombreComercial,
           c.Direccion, c.IdCiudad, ci.Nombre AS Ciudad, ci.IdDepartamento, d.Nombre AS Departamento,
           c.Telefono, c.Email, c.CupoCredito, c.DiasCredito, c.IdLista, lp.Nombre AS ListaPrecios,
           c.IdVendedor, u.Nombre AS Vendedor, c.Bloqueado, c.MotivoBloqueo, c.Activo, c.FechaCreacion,
           ISNULL((SELECT SUM(f.Saldo) FROM Facturas f WHERE f.IdCliente = c.IdCliente AND f.Estado = 'ACTIVA'), 0) AS Saldo
    FROM Clientes c
    LEFT JOIN Ciudades ci ON ci.IdCiudad = c.IdCiudad
    LEFT JOIN Departamentos d ON d.IdDepartamento = ci.IdDepartamento
    LEFT JOIN ListasPrecios lp ON lp.IdLista = c.IdLista
    LEFT JOIN Usuarios u ON u.IdUsuario = c.IdVendedor
    WHERE c.IdCliente = @IdCliente;
END
GO

CREATE PROCEDURE sp_Clientes_Guardar
    @IdCliente       INT,
    @TipoDocumento   VARCHAR(5),
    @NumeroDocumento VARCHAR(20),
    @DV              CHAR(1) = NULL,
    @RazonSocial     NVARCHAR(200),
    @NombreComercial NVARCHAR(200) = NULL,
    @Direccion       NVARCHAR(200) = NULL,
    @IdCiudad        INT = NULL,
    @Telefono        VARCHAR(30) = NULL,
    @Email           NVARCHAR(100) = NULL,
    @CupoCredito     DECIMAL(18,2),
    @DiasCredito     INT,
    @IdLista         INT = NULL,
    @IdVendedor      INT = NULL,
    @Bloqueado       BIT = 0,
    @MotivoBloqueo   NVARCHAR(200) = NULL,
    @Activo          BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- Solo valida duplicados al crear (al editar se puede duplicar... deuda conocida)
    IF @IdCliente = 0 AND EXISTS (SELECT 1 FROM Clientes WHERE NumeroDocumento = @NumeroDocumento)
    BEGIN
        RAISERROR('Ya existe un cliente con ese número de documento', 16, 1);
        RETURN;
    END

    IF @IdCliente = 0
    BEGIN
        INSERT INTO Clientes (TipoDocumento, NumeroDocumento, DV, RazonSocial, NombreComercial, Direccion, IdCiudad,
                              Telefono, Email, CupoCredito, DiasCredito, IdLista, IdVendedor, Bloqueado, MotivoBloqueo,
                              Activo, FechaCreacion)
        VALUES (@TipoDocumento, @NumeroDocumento, @DV, @RazonSocial, @NombreComercial, @Direccion, @IdCiudad,
                @Telefono, @Email, @CupoCredito, @DiasCredito, @IdLista, @IdVendedor, @Bloqueado, @MotivoBloqueo,
                @Activo, GETDATE());
        SET @IdCliente = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE Clientes
        SET TipoDocumento = @TipoDocumento, NumeroDocumento = @NumeroDocumento, DV = @DV,
            RazonSocial = @RazonSocial, NombreComercial = @NombreComercial, Direccion = @Direccion,
            IdCiudad = @IdCiudad, Telefono = @Telefono, Email = @Email, CupoCredito = @CupoCredito,
            DiasCredito = @DiasCredito, IdLista = @IdLista, IdVendedor = @IdVendedor,
            Bloqueado = @Bloqueado, MotivoBloqueo = @MotivoBloqueo, Activo = @Activo
        WHERE IdCliente = @IdCliente;
    END

    SELECT @IdCliente AS IdCliente;
END
GO

CREATE PROCEDURE sp_Clientes_SaldoCartera
    @IdCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.IdCliente,
           c.CupoCredito,
           ISNULL(SUM(f.Saldo), 0) AS Saldo,
           c.CupoCredito - ISNULL(SUM(f.Saldo), 0) AS Disponible,
           ISNULL(SUM(CASE WHEN f.FechaVencimiento < GETDATE() THEN f.Saldo ELSE 0 END), 0) AS SaldoVencido
    FROM Clientes c
    LEFT JOIN Facturas f ON f.IdCliente = c.IdCliente AND f.Estado = 'ACTIVA' AND f.Saldo > 0
    WHERE c.IdCliente = @IdCliente
    GROUP BY c.IdCliente, c.CupoCredito;
END
GO

CREATE PROCEDURE sp_Clientes_BloquearMorosos
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Clientes
    SET Bloqueado = 1, MotivoBloqueo = N'Cartera vencida mayor a 90 días'
    WHERE Bloqueado = 0
      AND IdCliente IN (SELECT IdCliente FROM Facturas
                        WHERE Estado = 'ACTIVA' AND Saldo > 0
                          AND DATEDIFF(DAY, FechaVencimiento, GETDATE()) > 90);
    SELECT @@ROWCOUNT AS ClientesBloqueados;
END
GO

/* ============================= INVENTARIO ============================= */
CREATE PROCEDURE sp_Inventario_Consultar
    @IdBodega INT = NULL,
    @Buscar   NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT i.IdBodega, b.Nombre AS Bodega, p.IdProducto, p.Codigo, p.Nombre AS Producto,
           c.Nombre AS Categoria, p.Unidad, i.Cantidad, i.CantidadReservada,
           i.Cantidad - i.CantidadReservada AS Disponible, p.StockMinimo, p.CostoPromedio,
           i.Cantidad * p.CostoPromedio AS ValorTotal,
           CASE WHEN i.Cantidad - i.CantidadReservada <= p.StockMinimo THEN 1 ELSE 0 END AS BajoMinimo
    FROM Inventario i
    INNER JOIN Bodegas b ON b.IdBodega = i.IdBodega
    INNER JOIN Productos p ON p.IdProducto = i.IdProducto
    INNER JOIN Categorias c ON c.IdCategoria = p.IdCategoria
    WHERE (@IdBodega IS NULL OR i.IdBodega = @IdBodega)
      AND (@Buscar IS NULL OR p.Nombre LIKE '%' + @Buscar + '%' OR p.Codigo LIKE '%' + @Buscar + '%')
    ORDER BY b.Nombre, p.Nombre;
END
GO

CREATE PROCEDURE sp_Inventario_Ajustar
    @IdBodega   INT,
    @IdProducto INT,
    @Cantidad   DECIMAL(18,2),
    @Motivo     NVARCHAR(200),
    @IdUsuario  INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Actual DECIMAL(18,2), @Reservada DECIMAL(18,2), @Costo DECIMAL(18,2), @IdAjuste INT;

    BEGIN TRY
        IF @Cantidad = 0
            RAISERROR('La cantidad del ajuste no puede ser cero', 16, 1);

        BEGIN TRAN;

        SELECT @Actual = Cantidad, @Reservada = CantidadReservada
        FROM Inventario WHERE IdBodega = @IdBodega AND IdProducto = @IdProducto;

        IF @Actual IS NULL
        BEGIN
            INSERT INTO Inventario (IdBodega, IdProducto, Cantidad, CantidadReservada) VALUES (@IdBodega, @IdProducto, 0, 0);
            SET @Actual = 0;
            SET @Reservada = 0;
        END

        IF @Actual + @Cantidad < @Reservada
            RAISERROR('El ajuste deja el inventario negativo o por debajo de lo reservado', 16, 1);

        UPDATE Inventario SET Cantidad = Cantidad + @Cantidad
        WHERE IdBodega = @IdBodega AND IdProducto = @IdProducto;

        INSERT INTO AjustesInventario (Fecha, IdBodega, IdProducto, Cantidad, Motivo, IdUsuario)
        VALUES (GETDATE(), @IdBodega, @IdProducto, @Cantidad, @Motivo, @IdUsuario);
        SET @IdAjuste = SCOPE_IDENTITY();

        SELECT @Costo = CostoPromedio FROM Productos WHERE IdProducto = @IdProducto;

        INSERT INTO Kardex (Fecha, IdProducto, IdBodega, TipoMovimiento, DocumentoRef, Cantidad, CostoUnitario,
                            SaldoCantidad, SaldoCosto, IdUsuario)
        VALUES (GETDATE(), @IdProducto, @IdBodega,
                CASE WHEN @Cantidad > 0 THEN 'AJU_POS' ELSE 'AJU_NEG' END,
                'AJU-' + CAST(@IdAjuste AS VARCHAR(10)), @Cantidad, @Costo, @Actual + @Cantidad, @Costo, @IdUsuario);

        COMMIT;
        SELECT @IdAjuste AS IdAjuste;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE sp_Kardex_Consultar
    @IdProducto INT,
    @IdBodega   INT = NULL,
    @Desde      DATETIME = NULL,
    @Hasta      DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT k.IdKardex, k.Fecha, k.IdBodega, b.Nombre AS Bodega, k.IdProducto, p.Codigo, p.Nombre AS Producto,
           k.TipoMovimiento, k.DocumentoRef, k.Cantidad, k.CostoUnitario, k.SaldoCantidad, k.SaldoCosto,
           u.Nombre AS Usuario
    FROM Kardex k
    INNER JOIN Bodegas b ON b.IdBodega = k.IdBodega
    INNER JOIN Productos p ON p.IdProducto = k.IdProducto
    LEFT JOIN Usuarios u ON u.IdUsuario = k.IdUsuario
    WHERE k.IdProducto = @IdProducto
      AND (@IdBodega IS NULL OR k.IdBodega = @IdBodega)
      AND (@Desde IS NULL OR k.Fecha >= @Desde)
      AND (@Hasta IS NULL OR k.Fecha < DATEADD(DAY, 1, @Hasta))
    ORDER BY k.Fecha, k.IdKardex;
END
GO

/* =============================== COMPRAS =============================== */
CREATE PROCEDURE sp_OrdenCompra_Guardar
    @Proveedor_Id  INT,
    @IdBodega      INT,
    @Observaciones NVARCHAR(500) = NULL,
    @IdUsuario     INT,
    @DetalleXml    XML
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdOrden INT, @Numero INT, @Prefijo VARCHAR(10);
    DECLARE @Det TABLE (IdProducto INT, Cantidad DECIMAL(18,2), CostoUnitario DECIMAL(18,2), PorcIva DECIMAL(5,2));

    INSERT INTO @Det (IdProducto, Cantidad, CostoUnitario, PorcIva)
    SELECT T.c.value('@idProducto', 'INT'),
           T.c.value('@cantidad', 'DECIMAL(18,2)'),
           T.c.value('@costo', 'DECIMAL(18,2)'),
           ISNULL(T.c.value('@iva', 'DECIMAL(5,2)'), p.PorcIva)
    FROM @DetalleXml.nodes('/items/item') T(c)
    INNER JOIN Productos p ON p.IdProducto = T.c.value('@idProducto', 'INT');

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM @Det)
            RAISERROR('La orden debe tener al menos un producto', 16, 1);
        IF EXISTS (SELECT 1 FROM @Det WHERE Cantidad <= 0 OR CostoUnitario < 0)
            RAISERROR('Hay cantidades o costos inválidos en la orden', 16, 1);

        BEGIN TRAN;

        EXEC sp_Consecutivo_Siguiente 'OC', @Numero OUTPUT, @Prefijo OUTPUT;

        INSERT INTO OrdenesCompra (Numero, Fecha, Proveedor_Id, IdBodega, Estado, Subtotal, Iva, Total, Observaciones, IdUsuario)
        SELECT @Numero, GETDATE(), @Proveedor_Id, @IdBodega, 'P',
               SUM(Cantidad * CostoUnitario),
               SUM(ROUND(Cantidad * CostoUnitario * PorcIva / 100, 2)),
               SUM(Cantidad * CostoUnitario) + SUM(ROUND(Cantidad * CostoUnitario * PorcIva / 100, 2)),
               @Observaciones, @IdUsuario
        FROM @Det;
        SET @IdOrden = SCOPE_IDENTITY();

        INSERT INTO OrdenesCompraDetalle (IdOrden, IdProducto, Cantidad, CantidadRecibida, CostoUnitario, PorcIva)
        SELECT @IdOrden, IdProducto, Cantidad, 0, CostoUnitario, PorcIva FROM @Det;

        COMMIT;
        SELECT @IdOrden AS IdOrden, @Numero AS Numero;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE sp_OrdenCompra_Listar
    @Estado CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT oc.IdOrden, oc.Numero, oc.Fecha, oc.Proveedor_Id, p.RazonSocial AS Proveedor, oc.IdBodega,
           b.Nombre AS Bodega, oc.Estado, oc.Subtotal, oc.Iva, oc.Total, oc.Observaciones, u.Nombre AS Usuario
    FROM OrdenesCompra oc
    INNER JOIN Proveedor p ON p.Proveedor_Id = oc.Proveedor_Id
    INNER JOIN Bodegas b ON b.IdBodega = oc.IdBodega
    LEFT JOIN Usuarios u ON u.IdUsuario = oc.IdUsuario
    WHERE @Estado IS NULL OR oc.Estado = @Estado
    ORDER BY oc.Fecha DESC;
END
GO

-- Devuelve 2 result sets: encabezado y detalle
CREATE PROCEDURE sp_OrdenCompra_Obtener
    @IdOrden INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT oc.IdOrden, oc.Numero, oc.Fecha, oc.Proveedor_Id, p.RazonSocial AS Proveedor, p.Nit, oc.IdBodega,
           b.Nombre AS Bodega, oc.Estado, oc.Subtotal, oc.Iva, oc.Total, oc.Observaciones, u.Nombre AS Usuario
    FROM OrdenesCompra oc
    INNER JOIN Proveedor p ON p.Proveedor_Id = oc.Proveedor_Id
    INNER JOIN Bodegas b ON b.IdBodega = oc.IdBodega
    LEFT JOIN Usuarios u ON u.IdUsuario = oc.IdUsuario
    WHERE oc.IdOrden = @IdOrden;

    SELECT d.IdDetalle, d.IdProducto, pr.Codigo, pr.Nombre AS Producto, d.Cantidad, d.CantidadRecibida,
           d.Cantidad - d.CantidadRecibida AS Pendiente, d.CostoUnitario, d.PorcIva,
           d.Cantidad * d.CostoUnitario AS Subtotal
    FROM OrdenesCompraDetalle d
    INNER JOIN Productos pr ON pr.IdProducto = d.IdProducto
    WHERE d.IdOrden = @IdOrden;
END
GO

-- AP-12: recalcula costo promedio, inventario, kardex y estado de la OC. Todo aquí.
CREATE PROCEDURE sp_Recepcion_Procesar
    @IdOrden    INT,
    @IdUsuario  INT,
    @DetalleXml XML
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdRecepcion INT, @Numero INT, @Prefijo VARCHAR(10), @IdBodega INT,
            @EstadoActual CHAR(1), @NuevoEstado CHAR(1);
    DECLARE @IdProducto INT, @Cantidad DECIMAL(18,2), @Costo DECIMAL(18,2);
    DECLARE @StockTotal DECIMAL(18,2), @CostoActual DECIMAL(18,2), @NuevoCosto DECIMAL(18,2), @SaldoBodega DECIMAL(18,2);
    DECLARE @Det TABLE (IdProducto INT, Cantidad DECIMAL(18,2), CostoUnitario DECIMAL(18,2));

    INSERT INTO @Det (IdProducto, Cantidad, CostoUnitario)
    SELECT T.c.value('@idProducto', 'INT'),
           T.c.value('@cantidad', 'DECIMAL(18,2)'),
           T.c.value('@costo', 'DECIMAL(18,2)')
    FROM @DetalleXml.nodes('/items/item') T(c);

    DELETE FROM @Det WHERE Cantidad IS NULL OR Cantidad <= 0;

    BEGIN TRY
        SELECT @IdBodega = IdBodega, @EstadoActual = Estado FROM OrdenesCompra WHERE IdOrden = @IdOrden;

        IF @IdBodega IS NULL
            RAISERROR('La orden de compra no existe', 16, 1);
        IF @EstadoActual NOT IN ('P', 'R')
            RAISERROR('La orden de compra no está pendiente de recepción', 16, 1);
        IF NOT EXISTS (SELECT 1 FROM @Det)
            RAISERROR('No hay cantidades para recibir', 16, 1);
        IF EXISTS (SELECT 1 FROM @Det d
                   LEFT JOIN OrdenesCompraDetalle od ON od.IdOrden = @IdOrden AND od.IdProducto = d.IdProducto
                   WHERE od.IdDetalle IS NULL OR d.Cantidad > od.Cantidad - od.CantidadRecibida)
            RAISERROR('Se intenta recibir más de lo pendiente o un producto que no está en la orden', 16, 1);

        BEGIN TRAN;

        EXEC sp_Consecutivo_Siguiente 'REC', @Numero OUTPUT, @Prefijo OUTPUT;

        INSERT INTO Recepciones (Numero, Fecha, IdOrden, IdUsuario) VALUES (@Numero, GETDATE(), @IdOrden, @IdUsuario);
        SET @IdRecepcion = SCOPE_IDENTITY();

        -- Cursor línea por línea (AP: se puede hacer set-based)
        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT IdProducto, Cantidad, CostoUnitario FROM @Det;
        OPEN cur;
        FETCH NEXT FROM cur INTO @IdProducto, @Cantidad, @Costo;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO RecepcionesDetalle (IdRecepcion, IdProducto, Cantidad, CostoUnitario)
            VALUES (@IdRecepcion, @IdProducto, @Cantidad, @Costo);

            -- Costo promedio ponderado (global, sumando todas las bodegas)
            SELECT @StockTotal = ISNULL(SUM(Cantidad), 0) FROM Inventario WHERE IdProducto = @IdProducto;
            SELECT @CostoActual = CostoPromedio FROM Productos WHERE IdProducto = @IdProducto;

            IF @StockTotal + @Cantidad > 0
                SET @NuevoCosto = ROUND((@StockTotal * @CostoActual + @Cantidad * @Costo) / (@StockTotal + @Cantidad), 2);
            ELSE
                SET @NuevoCosto = @Costo;

            UPDATE Productos SET CostoPromedio = @NuevoCosto WHERE IdProducto = @IdProducto;

            IF EXISTS (SELECT 1 FROM Inventario WHERE IdBodega = @IdBodega AND IdProducto = @IdProducto)
                UPDATE Inventario SET Cantidad = Cantidad + @Cantidad WHERE IdBodega = @IdBodega AND IdProducto = @IdProducto;
            ELSE
                INSERT INTO Inventario (IdBodega, IdProducto, Cantidad, CantidadReservada) VALUES (@IdBodega, @IdProducto, @Cantidad, 0);

            SELECT @SaldoBodega = Cantidad FROM Inventario WHERE IdBodega = @IdBodega AND IdProducto = @IdProducto;

            INSERT INTO Kardex (Fecha, IdProducto, IdBodega, TipoMovimiento, DocumentoRef, Cantidad, CostoUnitario,
                                SaldoCantidad, SaldoCosto, IdUsuario)
            VALUES (GETDATE(), @IdProducto, @IdBodega, 'ENT_COMPRA', 'REC-' + CAST(@Numero AS VARCHAR(10)),
                    @Cantidad, @Costo, @SaldoBodega, @NuevoCosto, @IdUsuario);

            UPDATE OrdenesCompraDetalle SET CantidadRecibida = CantidadRecibida + @Cantidad
            WHERE IdOrden = @IdOrden AND IdProducto = @IdProducto;

            FETCH NEXT FROM cur INTO @IdProducto, @Cantidad, @Costo;
        END
        CLOSE cur;
        DEALLOCATE cur;

        -- BUG-02: si la OC ya tenía una recepción parcial (estado 'R'), se queda en 'R'
        -- aunque con esta recepción se complete. Solo pasa a 'C' si se recibe todo de una vez.
        IF @EstadoActual = 'P' AND NOT EXISTS (SELECT 1 FROM OrdenesCompraDetalle WHERE IdOrden = @IdOrden AND CantidadRecibida < Cantidad)
        BEGIN
            SET @NuevoEstado = 'C';
        END
        ELSE
        BEGIN
            SET @NuevoEstado = 'R';
        END

        UPDATE OrdenesCompra SET Estado = @NuevoEstado WHERE IdOrden = @IdOrden;

        COMMIT;
        SELECT @IdRecepcion AS IdRecepcion, @Numero AS Numero, @NuevoEstado AS EstadoOrden;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

/* =============================== VENTAS =============================== */
-- El precio y el descuento por volumen se calculan en C# (AP-07) y llegan en el XML
CREATE PROCEDURE sp_Pedido_Guardar
    @IdCliente     INT,
    @IdVendedor    INT,
    @IdBodega      INT,
    @Observaciones NVARCHAR(500) = NULL,
    @DetalleXml    XML
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdPedido INT, @Numero INT, @Prefijo VARCHAR(10);
    DECLARE @Det TABLE (IdProducto INT, Cantidad DECIMAL(18,2), Precio DECIMAL(18,2), PorcDescuento DECIMAL(5,2),
                        PorcIva DECIMAL(5,2), Bruto DECIMAL(18,2), Descuento DECIMAL(18,2), ValorIva DECIMAL(18,2),
                        Total DECIMAL(18,2));

    INSERT INTO @Det (IdProducto, Cantidad, Precio, PorcDescuento, PorcIva)
    SELECT T.c.value('@idProducto', 'INT'),
           T.c.value('@cantidad', 'DECIMAL(18,2)'),
           T.c.value('@precio', 'DECIMAL(18,2)'),
           ISNULL(T.c.value('@descuento', 'DECIMAL(5,2)'), 0),
           ISNULL(T.c.value('@iva', 'DECIMAL(5,2)'), p.PorcIva)
    FROM @DetalleXml.nodes('/items/item') T(c)
    INNER JOIN Productos p ON p.IdProducto = T.c.value('@idProducto', 'INT');

    UPDATE @Det SET Bruto = Cantidad * Precio;
    UPDATE @Det SET Descuento = ROUND(Bruto * PorcDescuento / 100, 2);
    UPDATE @Det SET ValorIva = ROUND((Bruto - Descuento) * PorcIva / 100, 2);
    UPDATE @Det SET Total = Bruto - Descuento + ValorIva;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Clientes WHERE IdCliente = @IdCliente AND Activo = 1)
            RAISERROR('El cliente no existe o está inactivo', 16, 1);
        IF EXISTS (SELECT 1 FROM Clientes WHERE IdCliente = @IdCliente AND Bloqueado = 1)
            RAISERROR('El cliente está bloqueado y no puede recibir pedidos', 16, 1);
        IF NOT EXISTS (SELECT 1 FROM @Det)
            RAISERROR('El pedido debe tener al menos un producto', 16, 1);
        IF EXISTS (SELECT 1 FROM @Det WHERE Cantidad <= 0 OR Precio <= 0)
            RAISERROR('Hay cantidades o precios inválidos en el pedido', 16, 1);

        BEGIN TRAN;

        EXEC sp_Consecutivo_Siguiente 'PED', @Numero OUTPUT, @Prefijo OUTPUT;

        INSERT INTO Pedidos (Numero, Fecha, IdCliente, IdVendedor, IdBodega, Estado, Subtotal, Descuento, Iva, Total, Observaciones)
        SELECT @Numero, GETDATE(), @IdCliente, @IdVendedor, @IdBodega, 1,
               SUM(Bruto), SUM(Descuento), SUM(ValorIva), SUM(Total), @Observaciones
        FROM @Det;
        SET @IdPedido = SCOPE_IDENTITY();

        INSERT INTO PedidosDetalle (IdPedido, IdProducto, Cantidad, PrecioUnitario, PorcDescuento, PorcIva, Total)
        SELECT @IdPedido, IdProducto, Cantidad, Precio, PorcDescuento, PorcIva, Total FROM @Det;

        COMMIT;
        SELECT @IdPedido AS IdPedido, @Numero AS Numero;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE sp_Pedido_Aprobar
    @IdPedido  INT,
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Estado INT, @IdCliente INT, @IdBodega INT, @Total DECIMAL(18,2), @Numero INT;
    DECLARE @Cupo DECIMAL(18,2), @DiasCredito INT, @Bloqueado BIT, @Saldo DECIMAL(18,2);
    DECLARE @ProductoSinStock NVARCHAR(150);

    BEGIN TRY
        SELECT @Estado = Estado, @IdCliente = IdCliente, @IdBodega = IdBodega, @Total = Total, @Numero = Numero
        FROM Pedidos WHERE IdPedido = @IdPedido;

        IF @Estado IS NULL
            RAISERROR('El pedido no existe', 16, 1);
        IF @Estado <> 1
            RAISERROR('Solo se pueden aprobar pedidos en estado borrador', 16, 1);

        SELECT @Cupo = CupoCredito, @DiasCredito = DiasCredito, @Bloqueado = Bloqueado
        FROM Clientes WHERE IdCliente = @IdCliente;

        IF @Bloqueado = 1
            RAISERROR('El cliente está bloqueado', 16, 1);

        SELECT @Saldo = ISNULL(SUM(Saldo), 0) FROM Facturas WHERE IdCliente = @IdCliente AND Estado = 'ACTIVA';

        -- Clientes de contado (DiasCredito = 0) no se validan contra cupo
        IF @DiasCredito > 0 AND @Saldo + @Total > @Cupo
            RAISERROR('El pedido excede el cupo de crédito disponible del cliente', 16, 1);

        SELECT TOP 1 @ProductoSinStock = p.Nombre
        FROM (SELECT IdProducto, SUM(Cantidad) AS Cantidad FROM PedidosDetalle WHERE IdPedido = @IdPedido GROUP BY IdProducto) x
        INNER JOIN Productos p ON p.IdProducto = x.IdProducto
        LEFT JOIN Inventario i ON i.IdProducto = x.IdProducto AND i.IdBodega = @IdBodega
        WHERE x.Cantidad > ISNULL(i.Cantidad, 0) - ISNULL(i.CantidadReservada, 0);

        IF @ProductoSinStock IS NOT NULL
            RAISERROR('Stock insuficiente para el producto: %s', 16, 1, @ProductoSinStock);

        BEGIN TRAN;

        UPDATE i SET i.CantidadReservada = i.CantidadReservada + x.Cantidad
        FROM Inventario i
        INNER JOIN (SELECT IdProducto, SUM(Cantidad) AS Cantidad FROM PedidosDetalle WHERE IdPedido = @IdPedido GROUP BY IdProducto) x
            ON x.IdProducto = i.IdProducto
        WHERE i.IdBodega = @IdBodega;

        UPDATE Pedidos SET Estado = 2 WHERE IdPedido = @IdPedido;

        INSERT INTO LogSistema (Fecha, IdUsuario, Modulo, Accion, Detalle)
        VALUES (GETDATE(), @IdUsuario, 'Ventas', 'AprobarPedido', 'Pedido ' + CAST(@Numero AS VARCHAR(10)));

        COMMIT;
        SELECT @IdPedido AS IdPedido, 2 AS Estado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE sp_Pedido_Anular
    @IdPedido  INT,
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Estado INT, @IdBodega INT, @Numero INT;

    BEGIN TRY
        SELECT @Estado = Estado, @IdBodega = IdBodega, @Numero = Numero FROM Pedidos WHERE IdPedido = @IdPedido;

        IF @Estado IS NULL
            RAISERROR('El pedido no existe', 16, 1);
        IF @Estado = 3
            RAISERROR('El pedido ya fue facturado. Debe anular la factura.', 16, 1);
        IF @Estado = 4
            RAISERROR('El pedido ya está anulado', 16, 1);

        BEGIN TRAN;

        -- Si estaba aprobado, se libera la reserva
        IF @Estado = 2
        BEGIN
            UPDATE i SET i.CantidadReservada = CASE WHEN i.CantidadReservada - x.Cantidad < 0 THEN 0
                                                    ELSE i.CantidadReservada - x.Cantidad END
            FROM Inventario i
            INNER JOIN (SELECT IdProducto, SUM(Cantidad) AS Cantidad FROM PedidosDetalle WHERE IdPedido = @IdPedido GROUP BY IdProducto) x
                ON x.IdProducto = i.IdProducto
            WHERE i.IdBodega = @IdBodega;
        END

        UPDATE Pedidos SET Estado = 4 WHERE IdPedido = @IdPedido;

        INSERT INTO LogSistema (Fecha, IdUsuario, Modulo, Accion, Detalle)
        VALUES (GETDATE(), @IdUsuario, 'Ventas', 'AnularPedido', 'Pedido ' + CAST(@Numero AS VARCHAR(10)));

        COMMIT;
        SELECT @IdPedido AS IdPedido, 4 AS Estado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

/* ============================= FACTURACIÓN ============================= */
-- AP-12 / AP-21: el "procedimiento Dios" de la facturación
CREATE PROCEDURE sp_Factura_Generar
    @IdPedido  INT,
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Estado INT, @IdCliente INT, @IdBodega INT, @IdVendedor INT, @DiasCredito INT;
    DECLARE @Subtotal DECIMAL(18,2), @Descuento DECIMAL(18,2), @BaseIva DECIMAL(18,2), @Iva DECIMAL(18,2),
            @ReteFuente DECIMAL(18,2), @Total DECIMAL(18,2);
    DECLARE @PorcRete DECIMAL(5,2), @BaseRete DECIMAL(18,2);
    DECLARE @Numero INT, @Prefijo VARCHAR(10), @IdFactura INT, @Fecha DATETIME;
    DECLARE @IdProducto INT, @Cantidad DECIMAL(18,2), @Costo DECIMAL(18,2), @Saldo DECIMAL(18,2);

    SET @Fecha = GETDATE();

    BEGIN TRY
        SELECT @Estado = Estado, @IdCliente = IdCliente, @IdBodega = IdBodega, @IdVendedor = IdVendedor
        FROM Pedidos WHERE IdPedido = @IdPedido;

        IF @Estado IS NULL
            RAISERROR('El pedido no existe', 16, 1);
        IF @Estado <> 2
            RAISERROR('Solo se pueden facturar pedidos aprobados', 16, 1);

        SELECT @DiasCredito = DiasCredito FROM Clientes WHERE IdCliente = @IdCliente;

        SELECT @PorcRete = CAST(Valor AS DECIMAL(5,2)) FROM Parametros WHERE Clave = 'RETEFUENTE_PORC';
        SELECT @BaseRete = CAST(Valor AS DECIMAL(18,2)) FROM Parametros WHERE Clave = 'RETEFUENTE_BASE';

        -- Se recalculan los totales aunque el pedido ya los tiene (AP-06)
        SELECT @Subtotal  = SUM(Cantidad * PrecioUnitario),
               @Descuento = SUM(ROUND(Cantidad * PrecioUnitario * PorcDescuento / 100, 2)),
               @Iva       = SUM(ROUND((Cantidad * PrecioUnitario - ROUND(Cantidad * PrecioUnitario * PorcDescuento / 100, 2)) * PorcIva / 100, 2))
        FROM PedidosDetalle WHERE IdPedido = @IdPedido;

        SET @BaseIva = @Subtotal - @Descuento;

        -- BUG-01 (pareja): aquí se redondea a pesos (ROUND ... 0); la vista previa en C# usa otro redondeo
        IF @BaseIva >= @BaseRete
        BEGIN
            SET @ReteFuente = ROUND(@BaseIva * @PorcRete / 100, 0);
        END
        ELSE
        BEGIN
            SET @ReteFuente = 0;
        END

        SET @Total = @BaseIva + @Iva - @ReteFuente;

        BEGIN TRAN;

        EXEC sp_Consecutivo_Siguiente 'FAC', @Numero OUTPUT, @Prefijo OUTPUT;

        INSERT INTO Facturas (Prefijo, Numero, Fecha, FechaVencimiento, IdCliente, IdPedido, IdVendedor, Subtotal,
                              Descuento, BaseIva, Iva, ReteFuente, Total, Saldo, Estado, IdUsuario)
        VALUES (@Prefijo, @Numero, @Fecha, DATEADD(DAY, ISNULL(@DiasCredito, 0), @Fecha), @IdCliente, @IdPedido,
                @IdVendedor, @Subtotal, @Descuento, @BaseIva, @Iva, @ReteFuente, @Total, @Total, 'ACTIVA', @IdUsuario);
        SET @IdFactura = SCOPE_IDENTITY();

        INSERT INTO FacturasDetalle (IdFactura, IdProducto, Cantidad, PrecioUnitario, PorcDescuento, PorcIva, ValorIva,
                                     Total, CostoUnitario)
        SELECT @IdFactura, pd.IdProducto, pd.Cantidad, pd.PrecioUnitario, pd.PorcDescuento, pd.PorcIva,
               ROUND((pd.Cantidad * pd.PrecioUnitario - ROUND(pd.Cantidad * pd.PrecioUnitario * pd.PorcDescuento / 100, 2)) * pd.PorcIva / 100, 2),
               pd.Total, p.CostoPromedio
        FROM PedidosDetalle pd
        INNER JOIN Productos p ON p.IdProducto = pd.IdProducto
        WHERE pd.IdPedido = @IdPedido;

        -- Inventario y kardex línea por línea
        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT pd.IdProducto, pd.Cantidad, p.CostoPromedio
            FROM PedidosDetalle pd INNER JOIN Productos p ON p.IdProducto = pd.IdProducto
            WHERE pd.IdPedido = @IdPedido;
        OPEN cur;
        FETCH NEXT FROM cur INTO @IdProducto, @Cantidad, @Costo;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE Inventario
            SET Cantidad = Cantidad - @Cantidad,
                CantidadReservada = CASE WHEN CantidadReservada - @Cantidad < 0 THEN 0 ELSE CantidadReservada - @Cantidad END
            WHERE IdBodega = @IdBodega AND IdProducto = @IdProducto;

            SELECT @Saldo = Cantidad FROM Inventario WHERE IdBodega = @IdBodega AND IdProducto = @IdProducto;

            INSERT INTO Kardex (Fecha, IdProducto, IdBodega, TipoMovimiento, DocumentoRef, Cantidad, CostoUnitario,
                                SaldoCantidad, SaldoCosto, IdUsuario)
            VALUES (@Fecha, @IdProducto, @IdBodega, 'SAL_VENTA', @Prefijo + '-' + CAST(@Numero AS VARCHAR(10)),
                    -@Cantidad, @Costo, @Saldo, @Costo, @IdUsuario);

            FETCH NEXT FROM cur INTO @IdProducto, @Cantidad, @Costo;
        END
        CLOSE cur;
        DEALLOCATE cur;

        UPDATE Pedidos SET Estado = 3 WHERE IdPedido = @IdPedido;

        INSERT INTO LogSistema (Fecha, IdUsuario, Modulo, Accion, Detalle)
        VALUES (GETDATE(), @IdUsuario, 'Facturacion', 'Generar',
                '{"factura":"' + @Prefijo + '-' + CAST(@Numero AS VARCHAR(10)) + '","total":' + CAST(@Total AS VARCHAR(20)) + '}');

        COMMIT;
        SELECT @IdFactura AS IdFactura, @Prefijo AS Prefijo, @Numero AS Numero, @Total AS Total;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE sp_Factura_Anular
    @IdFactura INT,
    @Motivo    NVARCHAR(200),
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Estado VARCHAR(10), @IdPedido INT, @IdBodega INT, @Prefijo VARCHAR(10), @Numero INT;
    DECLARE @IdProducto INT, @Cantidad DECIMAL(18,2), @Costo DECIMAL(18,2), @Saldo DECIMAL(18,2), @CostoProm DECIMAL(18,2);

    BEGIN TRY
        SELECT @Estado = Estado, @IdPedido = IdPedido, @Prefijo = Prefijo, @Numero = Numero
        FROM Facturas WHERE IdFactura = @IdFactura;

        IF @Estado IS NULL
            RAISERROR('La factura no existe', 16, 1);
        IF @Estado <> 'ACTIVA'
            RAISERROR('La factura ya está anulada', 16, 1);
        IF EXISTS (SELECT 1 FROM AbonosDetalle ad INNER JOIN Abonos a ON a.IdAbono = ad.IdAbono
                   WHERE ad.IdFactura = @IdFactura AND a.Anulado = 0)
            RAISERROR('No se puede anular una factura que tiene abonos', 16, 1);

        SELECT @IdBodega = IdBodega FROM Pedidos WHERE IdPedido = @IdPedido;
        IF @IdBodega IS NULL SET @IdBodega = 1;   -- AP-07: bodega principal quemada

        BEGIN TRAN;

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT IdProducto, Cantidad, CostoUnitario FROM FacturasDetalle WHERE IdFactura = @IdFactura;
        OPEN cur;
        FETCH NEXT FROM cur INTO @IdProducto, @Cantidad, @Costo;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE Inventario SET Cantidad = Cantidad + @Cantidad WHERE IdBodega = @IdBodega AND IdProducto = @IdProducto;
            SELECT @Saldo = Cantidad FROM Inventario WHERE IdBodega = @IdBodega AND IdProducto = @IdProducto;
            SELECT @CostoProm = CostoPromedio FROM Productos WHERE IdProducto = @IdProducto;

            INSERT INTO Kardex (Fecha, IdProducto, IdBodega, TipoMovimiento, DocumentoRef, Cantidad, CostoUnitario,
                                SaldoCantidad, SaldoCosto, IdUsuario)
            VALUES (GETDATE(), @IdProducto, @IdBodega, 'ANU_VENTA', @Prefijo + '-' + CAST(@Numero AS VARCHAR(10)),
                    @Cantidad, @Costo, ISNULL(@Saldo, 0), @CostoProm, @IdUsuario);

            FETCH NEXT FROM cur INTO @IdProducto, @Cantidad, @Costo;
        END
        CLOSE cur;
        DEALLOCATE cur;

        UPDATE Facturas SET Estado = 'ANULADA', Saldo = 0, MotivoAnulacion = @Motivo WHERE IdFactura = @IdFactura;
        UPDATE Pedidos SET Estado = 4 WHERE IdPedido = @IdPedido;

        INSERT INTO LogSistema (Fecha, IdUsuario, Modulo, Accion, Detalle)
        VALUES (GETDATE(), @IdUsuario, 'Facturacion', 'Anular', @Prefijo + '-' + CAST(@Numero AS VARCHAR(10)) + ' Motivo: ' + ISNULL(@Motivo, ''));

        COMMIT;
        SELECT @IdFactura AS IdFactura, 'ANULADA' AS Estado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

-- Devuelve 2 result sets: encabezado y detalle
CREATE PROCEDURE sp_Factura_Obtener
    @IdFactura INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT f.IdFactura, f.Prefijo, f.Numero, f.Prefijo + '-' + CAST(f.Numero AS VARCHAR(10)) AS NumeroFactura,
           f.Fecha, f.FechaVencimiento, f.IdCliente, c.TipoDocumento, c.NumeroDocumento, c.DV, c.RazonSocial,
           c.Direccion, ci.Nombre AS Ciudad, c.Telefono, f.IdPedido, f.IdVendedor, u.Nombre AS Vendedor,
           f.Subtotal, f.Descuento, f.BaseIva, f.Iva, f.ReteFuente, f.Total, f.Saldo, f.Estado, f.MotivoAnulacion
    FROM Facturas f
    INNER JOIN Clientes c ON c.IdCliente = f.IdCliente
    LEFT JOIN Ciudades ci ON ci.IdCiudad = c.IdCiudad
    LEFT JOIN Usuarios u ON u.IdUsuario = f.IdVendedor
    WHERE f.IdFactura = @IdFactura;

    SELECT d.IdDetalle, d.IdProducto, p.Codigo, p.Nombre AS Producto, p.Unidad, d.Cantidad, d.PrecioUnitario,
           d.PorcDescuento, d.PorcIva, d.ValorIva, d.Total
    FROM FacturasDetalle d
    INNER JOIN Productos p ON p.IdProducto = d.IdProducto
    WHERE d.IdFactura = @IdFactura;
END
GO

CREATE PROCEDURE sp_Facturas_Listar
    @Desde     DATETIME = NULL,
    @Hasta     DATETIME = NULL,
    @IdCliente INT = NULL,
    @Estado    VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT f.IdFactura, f.Prefijo + '-' + CAST(f.Numero AS VARCHAR(10)) AS NumeroFactura, f.Fecha,
           f.FechaVencimiento, f.IdCliente, c.RazonSocial AS Cliente, u.Nombre AS Vendedor,
           f.Total, f.Saldo, f.Estado
    FROM Facturas f
    INNER JOIN Clientes c ON c.IdCliente = f.IdCliente
    LEFT JOIN Usuarios u ON u.IdUsuario = f.IdVendedor
    WHERE (@Desde IS NULL OR f.Fecha >= @Desde)
      AND (@Hasta IS NULL OR f.Fecha < DATEADD(DAY, 1, @Hasta))
      AND (@IdCliente IS NULL OR f.IdCliente = @IdCliente)
      AND (@Estado IS NULL OR f.Estado = @Estado)
    ORDER BY f.Fecha DESC;
END
GO

/* =============================== CARTERA =============================== */
-- Aplica el abono a las facturas más antiguas primero (FIFO)
CREATE PROCEDURE sp_Abono_Registrar
    @IdCliente  INT,
    @Valor      DECIMAL(18,2),
    @FormaPago  VARCHAR(20),
    @Referencia NVARCHAR(50) = NULL,
    @IdUsuario  INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SaldoTotal DECIMAL(18,2), @IdAbono INT, @Numero INT, @Prefijo VARCHAR(10);
    DECLARE @Restante DECIMAL(18,2), @IdFactura INT, @SaldoFactura DECIMAL(18,2), @Aplicar DECIMAL(18,2);

    BEGIN TRY
        IF @Valor <= 0
            RAISERROR('El valor del abono debe ser mayor a cero', 16, 1);

        SELECT @SaldoTotal = ISNULL(SUM(Saldo), 0)
        FROM Facturas WHERE IdCliente = @IdCliente AND Estado = 'ACTIVA' AND Saldo > 0;

        IF @Valor > @SaldoTotal
            RAISERROR('El abono supera el saldo pendiente del cliente', 16, 1);

        BEGIN TRAN;

        EXEC sp_Consecutivo_Siguiente 'ABO', @Numero OUTPUT, @Prefijo OUTPUT;

        INSERT INTO Abonos (Numero, Fecha, IdCliente, Valor, FormaPago, Referencia, IdUsuario, Anulado)
        VALUES (@Numero, GETDATE(), @IdCliente, @Valor, @FormaPago, @Referencia, @IdUsuario, 0);
        SET @IdAbono = SCOPE_IDENTITY();

        SET @Restante = @Valor;

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT IdFactura, Saldo FROM Facturas
            WHERE IdCliente = @IdCliente AND Estado = 'ACTIVA' AND Saldo > 0
            ORDER BY Fecha, IdFactura;
        OPEN cur;
        FETCH NEXT FROM cur INTO @IdFactura, @SaldoFactura;
        WHILE @@FETCH_STATUS = 0 AND @Restante > 0
        BEGIN
            SET @Aplicar = CASE WHEN @Restante >= @SaldoFactura THEN @SaldoFactura ELSE @Restante END;

            INSERT INTO AbonosDetalle (IdAbono, IdFactura, ValorAplicado) VALUES (@IdAbono, @IdFactura, @Aplicar);
            UPDATE Facturas SET Saldo = Saldo - @Aplicar WHERE IdFactura = @IdFactura;

            SET @Restante = @Restante - @Aplicar;
            FETCH NEXT FROM cur INTO @IdFactura, @SaldoFactura;
        END
        CLOSE cur;
        DEALLOCATE cur;

        COMMIT;
        SELECT @IdAbono AS IdAbono, @Numero AS Numero;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE PROCEDURE sp_Cartera_EstadoCuenta
    @IdCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT f.IdFactura, f.Prefijo + '-' + CAST(f.Numero AS VARCHAR(10)) AS NumeroFactura, f.Fecha,
           f.FechaVencimiento, f.Total, f.Saldo,
           DATEDIFF(DAY, f.FechaVencimiento, GETDATE()) AS DiasVencidos,
           CASE WHEN DATEDIFF(DAY, f.FechaVencimiento, GETDATE()) <= 30 THEN '0-30'
                WHEN DATEDIFF(DAY, f.FechaVencimiento, GETDATE()) <= 60 THEN '31-60'
                WHEN DATEDIFF(DAY, f.FechaVencimiento, GETDATE()) <= 90 THEN '61-90'
                ELSE '>90' END AS Rango
    FROM Facturas f
    WHERE f.IdCliente = @IdCliente AND f.Estado = 'ACTIVA' AND f.Saldo > 0
    ORDER BY f.Fecha;
END
GO

PRINT 'Stored procedures creados';
GO
