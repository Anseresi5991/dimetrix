/* =====================================================================
   DistriMax - 02 Tablas
   Nota: nombres inconsistentes a propósito (AP-26): plural/singular,
   IdX / X_Id, estados como int, char y string (AP-08).
   ===================================================================== */
USE DistriMaxDB;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ============================ SEGURIDAD ============================ */
CREATE TABLE Roles (
    IdRol           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Roles PRIMARY KEY,
    Nombre          NVARCHAR(50)  NOT NULL,
    Activo          BIT           NOT NULL CONSTRAINT DF_Roles_Activo DEFAULT (1)
);

-- La tabla existe pero el código NO la usa: los permisos están quemados con ifs (AP-09)
CREATE TABLE Permisos (
    IdPermiso       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Permisos PRIMARY KEY,
    Codigo          VARCHAR(30)   NOT NULL,
    Descripcion     NVARCHAR(200) NULL
);

CREATE TABLE RolesPermisos (
    IdRol           INT NOT NULL CONSTRAINT FK_RolesPermisos_Roles REFERENCES Roles(IdRol),
    IdPermiso       INT NOT NULL CONSTRAINT FK_RolesPermisos_Permisos REFERENCES Permisos(IdPermiso),
    CONSTRAINT PK_RolesPermisos PRIMARY KEY (IdRol, IdPermiso)
);

CREATE TABLE Usuarios (
    IdUsuario       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Usuarios PRIMARY KEY,
    Login           NVARCHAR(50)  NOT NULL CONSTRAINT UQ_Usuarios_Login UNIQUE,
    Password        VARCHAR(32)   NOT NULL,          -- AP-20: MD5 sin salt
    Nombre          NVARCHAR(100) NOT NULL,
    Email           NVARCHAR(100) NULL,
    IdRol           INT           NOT NULL CONSTRAINT FK_Usuarios_Roles REFERENCES Roles(IdRol),
    Token           NVARCHAR(50)  NULL,               -- token "casero" (GUID)
    TokenExpira     DATETIME      NULL,
    Activo          BIT           NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT (1),
    FechaCreacion   DATETIME      NOT NULL CONSTRAINT DF_Usuarios_Fecha DEFAULT (GETDATE()),
    UltimoAcceso    DATETIME      NULL
);
GO

/* ========================= MAESTROS GENERALES ========================= */
CREATE TABLE Departamentos (
    IdDepartamento  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Departamentos PRIMARY KEY,
    Codigo          VARCHAR(5)    NOT NULL,           -- código DANE
    Nombre          NVARCHAR(100) NOT NULL
);

CREATE TABLE Ciudades (
    IdCiudad        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Ciudades PRIMARY KEY,
    IdDepartamento  INT           NOT NULL CONSTRAINT FK_Ciudades_Departamentos REFERENCES Departamentos(IdDepartamento),
    Codigo          VARCHAR(10)   NOT NULL,           -- código DANE
    Nombre          NVARCHAR(100) NOT NULL
);

-- AP-07: estos valores también están quemados en el código
CREATE TABLE Parametros (
    Clave           VARCHAR(50)   NOT NULL CONSTRAINT PK_Parametros PRIMARY KEY,
    Valor           NVARCHAR(200) NOT NULL,
    Descripcion     NVARCHAR(200) NULL
);

CREATE TABLE Consecutivos (
    Tipo            VARCHAR(5)    NOT NULL CONSTRAINT PK_Consecutivos PRIMARY KEY,
    Prefijo         VARCHAR(10)   NULL,
    Actual          INT           NOT NULL CONSTRAINT DF_Consecutivos_Actual DEFAULT (0)
);
GO

/* ======================= PRODUCTOS E INVENTARIO ======================= */
CREATE TABLE Categorias (
    IdCategoria      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Categorias PRIMARY KEY,
    Nombre           NVARCHAR(100) NOT NULL,
    IdCategoriaPadre INT           NULL CONSTRAINT FK_Categorias_Padre REFERENCES Categorias(IdCategoria),
    Activa           BIT           NOT NULL CONSTRAINT DF_Categorias_Activa DEFAULT (1)
);

CREATE TABLE Productos (
    IdProducto      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Productos PRIMARY KEY,
    Codigo          VARCHAR(20)   NOT NULL CONSTRAINT UQ_Productos_Codigo UNIQUE,
    CodigoBarras    VARCHAR(20)   NULL,
    Nombre          NVARCHAR(150) NOT NULL,
    Descripcion     NVARCHAR(500) NULL,
    IdCategoria     INT           NOT NULL CONSTRAINT FK_Productos_Categorias REFERENCES Categorias(IdCategoria),
    Unidad          VARCHAR(10)   NOT NULL CONSTRAINT DF_Productos_Unidad DEFAULT ('UND'),
    PorcIva         DECIMAL(5,2)  NOT NULL CONSTRAINT DF_Productos_Iva DEFAULT (19),
    CostoPromedio   DECIMAL(18,2) NOT NULL CONSTRAINT DF_Productos_Costo DEFAULT (0),
    PrecioBase      DECIMAL(18,2) NOT NULL CONSTRAINT DF_Productos_Precio DEFAULT (0),
    StockMinimo     DECIMAL(18,2) NOT NULL CONSTRAINT DF_Productos_StockMin DEFAULT (0),
    Activo          BIT           NOT NULL CONSTRAINT DF_Productos_Activo DEFAULT (1)
);

CREATE TABLE Bodegas (
    IdBodega        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Bodegas PRIMARY KEY,
    Nombre          NVARCHAR(100) NOT NULL,
    Direccion       NVARCHAR(200) NULL,
    Activa          BIT           NOT NULL CONSTRAINT DF_Bodegas_Activa DEFAULT (1)
);

CREATE TABLE Inventario (
    IdBodega          INT           NOT NULL CONSTRAINT FK_Inventario_Bodegas REFERENCES Bodegas(IdBodega),
    IdProducto        INT           NOT NULL CONSTRAINT FK_Inventario_Productos REFERENCES Productos(IdProducto),
    Cantidad          DECIMAL(18,2) NOT NULL CONSTRAINT DF_Inventario_Cantidad DEFAULT (0),
    CantidadReservada DECIMAL(18,2) NOT NULL CONSTRAINT DF_Inventario_Reservada DEFAULT (0),
    CONSTRAINT PK_Inventario PRIMARY KEY (IdBodega, IdProducto)
);

-- Cantidad: positiva para entradas, negativa para salidas
CREATE TABLE Kardex (
    IdKardex        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Kardex PRIMARY KEY,
    Fecha           DATETIME      NOT NULL CONSTRAINT DF_Kardex_Fecha DEFAULT (GETDATE()),
    IdProducto      INT           NOT NULL CONSTRAINT FK_Kardex_Productos REFERENCES Productos(IdProducto),
    IdBodega        INT           NOT NULL CONSTRAINT FK_Kardex_Bodegas REFERENCES Bodegas(IdBodega),
    TipoMovimiento  VARCHAR(20)   NOT NULL,   -- ENT_COMPRA, SAL_VENTA, AJU_POS, AJU_NEG, ANU_VENTA, TRASLADO
    DocumentoRef    VARCHAR(50)   NULL,
    Cantidad        DECIMAL(18,2) NOT NULL,
    CostoUnitario   DECIMAL(18,2) NOT NULL,
    SaldoCantidad   DECIMAL(18,2) NOT NULL,   -- saldo en la bodega después del movimiento
    SaldoCosto      DECIMAL(18,2) NOT NULL,   -- costo promedio del producto después del movimiento
    IdUsuario       INT           NULL CONSTRAINT FK_Kardex_Usuarios REFERENCES Usuarios(IdUsuario)
);

CREATE TABLE AjustesInventario (
    IdAjuste        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AjustesInventario PRIMARY KEY,
    Fecha           DATETIME      NOT NULL CONSTRAINT DF_Ajustes_Fecha DEFAULT (GETDATE()),
    IdBodega        INT           NOT NULL CONSTRAINT FK_Ajustes_Bodegas REFERENCES Bodegas(IdBodega),
    IdProducto      INT           NOT NULL CONSTRAINT FK_Ajustes_Productos REFERENCES Productos(IdProducto),
    Cantidad        DECIMAL(18,2) NOT NULL,
    Motivo          NVARCHAR(200) NULL,
    IdUsuario       INT           NULL CONSTRAINT FK_Ajustes_Usuarios REFERENCES Usuarios(IdUsuario)
);
GO

/* ========================= CLIENTES Y PRECIOS ========================= */
CREATE TABLE ListasPrecios (
    IdLista         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ListasPrecios PRIMARY KEY,
    Nombre          NVARCHAR(50)  NOT NULL,
    Activa          BIT           NOT NULL CONSTRAINT DF_ListasPrecios_Activa DEFAULT (1)
);

CREATE TABLE ListasPreciosDetalle (
    IdLista         INT           NOT NULL CONSTRAINT FK_LPD_Listas REFERENCES ListasPrecios(IdLista),
    IdProducto      INT           NOT NULL CONSTRAINT FK_LPD_Productos REFERENCES Productos(IdProducto),
    Precio          DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_ListasPreciosDetalle PRIMARY KEY (IdLista, IdProducto)
);

-- Sin UNIQUE en NumeroDocumento: se valida (a medias) en el SP
CREATE TABLE Clientes (
    IdCliente       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Clientes PRIMARY KEY,
    TipoDocumento   VARCHAR(5)    NOT NULL CONSTRAINT DF_Clientes_TipoDoc DEFAULT ('NIT'),
    NumeroDocumento VARCHAR(20)   NOT NULL,
    DV              CHAR(1)       NULL,
    RazonSocial     NVARCHAR(200) NOT NULL,
    NombreComercial NVARCHAR(200) NULL,
    Direccion       NVARCHAR(200) NULL,
    IdCiudad        INT           NULL CONSTRAINT FK_Clientes_Ciudades REFERENCES Ciudades(IdCiudad),
    Telefono        VARCHAR(30)   NULL,
    Email           NVARCHAR(100) NULL,
    CupoCredito     DECIMAL(18,2) NOT NULL CONSTRAINT DF_Clientes_Cupo DEFAULT (0),
    DiasCredito     INT           NOT NULL CONSTRAINT DF_Clientes_Dias DEFAULT (0),
    IdLista         INT           NULL CONSTRAINT FK_Clientes_Listas REFERENCES ListasPrecios(IdLista),
    IdVendedor      INT           NULL CONSTRAINT FK_Clientes_Vendedor REFERENCES Usuarios(IdUsuario),
    Bloqueado       BIT           NOT NULL CONSTRAINT DF_Clientes_Bloqueado DEFAULT (0),
    MotivoBloqueo   NVARCHAR(200) NULL,
    Activo          BIT           NOT NULL CONSTRAINT DF_Clientes_Activo DEFAULT (1),
    FechaCreacion   DATETIME      NOT NULL CONSTRAINT DF_Clientes_Fecha DEFAULT (GETDATE())
);
GO

/* ============================ PROVEEDORES ============================ */
-- AP-26: tabla en singular y PK con otro estilo
CREATE TABLE Proveedor (
    Proveedor_Id    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Proveedor PRIMARY KEY,
    Nit             VARCHAR(20)   NOT NULL,
    DV              CHAR(1)       NULL,
    RazonSocial     NVARCHAR(200) NOT NULL,
    Contacto        NVARCHAR(100) NULL,
    Telefono        VARCHAR(30)   NULL,
    Email           NVARCHAR(100) NULL,
    IdCiudad        INT           NULL CONSTRAINT FK_Proveedor_Ciudades REFERENCES Ciudades(IdCiudad),
    DiasPago        INT           NOT NULL CONSTRAINT DF_Proveedor_DiasPago DEFAULT (30),
    Activo          BIT           NOT NULL CONSTRAINT DF_Proveedor_Activo DEFAULT (1)
);
GO

/* ============================== COMPRAS ============================== */
-- Estado (AP-08): P = Pendiente, R = Recibida parcial, C = Cerrada, A = Anulada
CREATE TABLE OrdenesCompra (
    IdOrden         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OrdenesCompra PRIMARY KEY,
    Numero          INT           NOT NULL,
    Fecha           DATETIME      NOT NULL CONSTRAINT DF_OC_Fecha DEFAULT (GETDATE()),
    Proveedor_Id    INT           NOT NULL CONSTRAINT FK_OC_Proveedor REFERENCES Proveedor(Proveedor_Id),
    IdBodega        INT           NOT NULL CONSTRAINT FK_OC_Bodegas REFERENCES Bodegas(IdBodega),
    Estado          CHAR(1)       NOT NULL CONSTRAINT DF_OC_Estado DEFAULT ('P'),
    Subtotal        DECIMAL(18,2) NOT NULL CONSTRAINT DF_OC_Subtotal DEFAULT (0),
    Iva             DECIMAL(18,2) NOT NULL CONSTRAINT DF_OC_Iva DEFAULT (0),
    Total           DECIMAL(18,2) NOT NULL CONSTRAINT DF_OC_Total DEFAULT (0),
    Observaciones   NVARCHAR(500) NULL,
    IdUsuario       INT           NULL CONSTRAINT FK_OC_Usuarios REFERENCES Usuarios(IdUsuario)
);

CREATE TABLE OrdenesCompraDetalle (
    IdDetalle        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OrdenesCompraDetalle PRIMARY KEY,
    IdOrden          INT           NOT NULL CONSTRAINT FK_OCD_OC REFERENCES OrdenesCompra(IdOrden),
    IdProducto       INT           NOT NULL CONSTRAINT FK_OCD_Productos REFERENCES Productos(IdProducto),
    Cantidad         DECIMAL(18,2) NOT NULL,
    CantidadRecibida DECIMAL(18,2) NOT NULL CONSTRAINT DF_OCD_Recibida DEFAULT (0),
    CostoUnitario    DECIMAL(18,2) NOT NULL,
    PorcIva          DECIMAL(5,2)  NOT NULL
);

CREATE TABLE Recepciones (
    IdRecepcion     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Recepciones PRIMARY KEY,
    Numero          INT           NOT NULL,
    Fecha           DATETIME      NOT NULL CONSTRAINT DF_Recepciones_Fecha DEFAULT (GETDATE()),
    IdOrden         INT           NOT NULL CONSTRAINT FK_Recepciones_OC REFERENCES OrdenesCompra(IdOrden),
    IdUsuario       INT           NULL CONSTRAINT FK_Recepciones_Usuarios REFERENCES Usuarios(IdUsuario)
);

CREATE TABLE RecepcionesDetalle (
    IdDetalle       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RecepcionesDetalle PRIMARY KEY,
    IdRecepcion     INT           NOT NULL CONSTRAINT FK_RD_Recepciones REFERENCES Recepciones(IdRecepcion),
    IdProducto      INT           NOT NULL CONSTRAINT FK_RD_Productos REFERENCES Productos(IdProducto),
    Cantidad        DECIMAL(18,2) NOT NULL,
    CostoUnitario   DECIMAL(18,2) NOT NULL
);
GO

/* =============================== VENTAS =============================== */
-- Estado (AP-08): 1 = Borrador, 2 = Aprobado, 3 = Facturado, 4 = Anulado
CREATE TABLE Pedidos (
    IdPedido        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Pedidos PRIMARY KEY,
    Numero          INT           NOT NULL,
    Fecha           DATETIME      NOT NULL CONSTRAINT DF_Pedidos_Fecha DEFAULT (GETDATE()),
    IdCliente       INT           NOT NULL CONSTRAINT FK_Pedidos_Clientes REFERENCES Clientes(IdCliente),
    IdVendedor      INT           NULL CONSTRAINT FK_Pedidos_Vendedor REFERENCES Usuarios(IdUsuario),
    IdBodega        INT           NOT NULL CONSTRAINT FK_Pedidos_Bodegas REFERENCES Bodegas(IdBodega),
    Estado          INT           NOT NULL CONSTRAINT DF_Pedidos_Estado DEFAULT (1),
    Subtotal        DECIMAL(18,2) NOT NULL CONSTRAINT DF_Pedidos_Subtotal DEFAULT (0),
    Descuento       DECIMAL(18,2) NOT NULL CONSTRAINT DF_Pedidos_Descuento DEFAULT (0),
    Iva             DECIMAL(18,2) NOT NULL CONSTRAINT DF_Pedidos_Iva DEFAULT (0),
    Total           DECIMAL(18,2) NOT NULL CONSTRAINT DF_Pedidos_Total DEFAULT (0),
    Observaciones   NVARCHAR(500) NULL
);

CREATE TABLE PedidosDetalle (
    IdDetalle       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PedidosDetalle PRIMARY KEY,
    IdPedido        INT           NOT NULL CONSTRAINT FK_PD_Pedidos REFERENCES Pedidos(IdPedido),
    IdProducto      INT           NOT NULL CONSTRAINT FK_PD_Productos REFERENCES Productos(IdProducto),
    Cantidad        DECIMAL(18,2) NOT NULL,
    PrecioUnitario  DECIMAL(18,2) NOT NULL,
    PorcDescuento   DECIMAL(5,2)  NOT NULL CONSTRAINT DF_PD_Descuento DEFAULT (0),
    PorcIva         DECIMAL(5,2)  NOT NULL,
    Total           DECIMAL(18,2) NOT NULL
);
GO

/* ============================ FACTURACIÓN ============================ */
-- Estado (AP-08): 'ACTIVA' / 'ANULADA'
CREATE TABLE Facturas (
    IdFactura        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Facturas PRIMARY KEY,
    Prefijo          VARCHAR(10)   NOT NULL,
    Numero           INT           NOT NULL,
    Fecha            DATETIME      NOT NULL CONSTRAINT DF_Facturas_Fecha DEFAULT (GETDATE()),
    FechaVencimiento DATETIME      NOT NULL,
    IdCliente        INT           NOT NULL CONSTRAINT FK_Facturas_Clientes REFERENCES Clientes(IdCliente),
    IdPedido         INT           NULL CONSTRAINT FK_Facturas_Pedidos REFERENCES Pedidos(IdPedido),
    IdVendedor       INT           NULL CONSTRAINT FK_Facturas_Vendedor REFERENCES Usuarios(IdUsuario),
    Subtotal         DECIMAL(18,2) NOT NULL,
    Descuento        DECIMAL(18,2) NOT NULL,
    BaseIva          DECIMAL(18,2) NOT NULL,
    Iva              DECIMAL(18,2) NOT NULL,
    ReteFuente       DECIMAL(18,2) NOT NULL,
    Total            DECIMAL(18,2) NOT NULL,
    Saldo            DECIMAL(18,2) NOT NULL,
    Estado           VARCHAR(10)   NOT NULL CONSTRAINT DF_Facturas_Estado DEFAULT ('ACTIVA'),
    MotivoAnulacion  NVARCHAR(200) NULL,
    IdUsuario        INT           NULL CONSTRAINT FK_Facturas_Usuarios REFERENCES Usuarios(IdUsuario)
);

CREATE TABLE FacturasDetalle (
    IdDetalle       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FacturasDetalle PRIMARY KEY,
    IdFactura       INT           NOT NULL CONSTRAINT FK_FD_Facturas REFERENCES Facturas(IdFactura),
    IdProducto      INT           NOT NULL CONSTRAINT FK_FD_Productos REFERENCES Productos(IdProducto),
    Cantidad        DECIMAL(18,2) NOT NULL,
    PrecioUnitario  DECIMAL(18,2) NOT NULL,
    PorcDescuento   DECIMAL(5,2)  NOT NULL,
    PorcIva         DECIMAL(5,2)  NOT NULL,
    ValorIva        DECIMAL(18,2) NOT NULL,
    Total           DECIMAL(18,2) NOT NULL,
    CostoUnitario   DECIMAL(18,2) NOT NULL
);
GO

/* ============================== CARTERA ============================== */
CREATE TABLE Abonos (
    IdAbono         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Abonos PRIMARY KEY,
    Numero          INT           NOT NULL,
    Fecha           DATETIME      NOT NULL CONSTRAINT DF_Abonos_Fecha DEFAULT (GETDATE()),
    IdCliente       INT           NOT NULL CONSTRAINT FK_Abonos_Clientes REFERENCES Clientes(IdCliente),
    Valor           DECIMAL(18,2) NOT NULL,
    FormaPago       VARCHAR(20)   NOT NULL,
    Referencia      NVARCHAR(50)  NULL,
    IdUsuario       INT           NULL CONSTRAINT FK_Abonos_Usuarios REFERENCES Usuarios(IdUsuario),
    Anulado         BIT           NOT NULL CONSTRAINT DF_Abonos_Anulado DEFAULT (0)
);

CREATE TABLE AbonosDetalle (
    IdAbonoDetalle  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AbonosDetalle PRIMARY KEY,
    IdAbono         INT           NOT NULL CONSTRAINT FK_AD_Abonos REFERENCES Abonos(IdAbono),
    IdFactura       INT           NOT NULL CONSTRAINT FK_AD_Facturas REFERENCES Facturas(IdFactura),
    ValorAplicado   DECIMAL(18,2) NOT NULL
);
GO

/* ============================= AUDITORÍA ============================= */
-- Sin FK a Usuarios (a propósito: se loguean intentos con IdUsuario = 0)
CREATE TABLE LogSistema (
    IdLog           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_LogSistema PRIMARY KEY,
    Fecha           DATETIME      NOT NULL CONSTRAINT DF_LogSistema_Fecha DEFAULT (GETDATE()),
    IdUsuario       INT           NULL,
    Modulo          NVARCHAR(50)  NULL,
    Accion          NVARCHAR(100) NULL,
    Detalle         NVARCHAR(MAX) NULL      -- a veces JSON, a veces texto libre
);

CREATE TABLE LogErrores (
    IdError         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_LogErrores PRIMARY KEY,
    Fecha           DATETIME      NOT NULL CONSTRAINT DF_LogErrores_Fecha DEFAULT (GETDATE()),
    Origen          VARCHAR(10)   NULL,      -- WEB / API
    Mensaje         NVARCHAR(MAX) NULL,
    StackTrace      NVARCHAR(MAX) NULL,
    Url             NVARCHAR(500) NULL
);
GO

-- Índices: casi ninguno (deuda técnica a propósito). Solo uno que "alguien" agregó.
CREATE INDEX IX_Facturas_IdCliente ON Facturas (IdCliente);
GO

PRINT 'Tablas creadas';
GO
