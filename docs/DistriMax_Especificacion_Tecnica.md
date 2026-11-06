# DistriMax — Especificación Técnica (Proyecto Legacy)

> **Propósito:** construir un sistema "legacy realista" en .NET Framework, intencionalmente sin buenas prácticas ni SOLID, que **funcione correctamente** y sirva luego como base para ejercicios de refactorización y migración a .NET moderno (8/9+).
>
> **Regla de oro:** feo por dentro, correcto por fuera. Toda la funcionalidad debe operar bien; la deuda técnica es deliberada y está catalogada (ver sección 9).

---

## 1. Visión general

**DistriMax** es un sistema de gestión para una distribuidora mayorista colombiana de tamaño mediano. Cubre seguridad, maestros, inventario, compras, ventas, facturación, cartera, reportes y auditoría.

| Ítem | Valor |
|---|---|
| Nombre | DistriMax |
| Dominio | Distribución mayorista (Colombia) |
| Moneda | COP (sin decimales en presentación, `decimal(18,2)` en BD) |
| Idioma UI | Español |
| Usuarios objetivo | Administrador, Vendedor, Bodeguero, Cartera, Gerencia |
| Tamaño estimado | ~30 tablas, ~40 stored procedures, ~12 controllers API, ~12 controllers MVC |

---

## 2. Stack tecnológico ("de época")

| Capa | Tecnología | Versión |
|---|---|---|
| Framework | .NET Framework | 4.8 |
| Front | ASP.NET MVC 5 + Razor | Microsoft.AspNet.Mvc 5.2.9 |
| API | ASP.NET Web API 2 | Microsoft.AspNet.WebApi 5.2.9 |
| ORM (parcial) | Entity Framework 6 — DbContext sobre BD existente (sin .edmx) | 6.4.4 |
| Acceso a datos (parcial) | ADO.NET (`SqlConnection`, `SqlCommand`, `DataTable`) | — |
| JSON | Newtonsoft.Json | 13.0.3 |
| Front JS/CSS | jQuery + Bootstrap 3 + DataTables, cargados desde CDN (cdnjs) | jQuery 3.4.1 / Bootstrap 3.4.1 / DataTables 1.10.21 |
| Base de datos | SQL Server LocalDB o Express | 2019+ |
| Hosting local | IIS Express (Visual Studio) | — |
| IDE | Visual Studio 2022 (workload "ASP.NET and web development") | — |

**Requisito:** Windows. .NET Framework 4.8 no corre en Linux/macOS.

---

## 3. Estructura de la solución

```
DistriMax/
├── DistriMax.sln
├── DistriMax.Web/            → ASP.NET MVC 5 (front)
│   ├── Controllers/
│   ├── Views/
│   ├── Models/               → ViewModels + algunos modelos con lógica (AP)
│   ├── Helpers/              → ApiHelper, SessionHelper, FormatoHelper
│   ├── Scripts/              → jQuery, JS por módulo (y JS inline en vistas)
│   ├── Content/
│   └── Web.config
├── DistriMax.Api/            → ASP.NET Web API 2
│   ├── Controllers/
│   ├── Data/                 → DistriMaxEntities.cs (EF6) + DbHelper.cs (ADO.NET)
│   ├── Helpers/              → TokenHelper, Utils, LogHelper, CalculosHelper
│   └── Web.config
├── DistriMax.Common/         → Class Library (.NET Framework 4.8)
│   ├── DTOs/
│   ├── Constantes.cs
│   └── Utils.cs              → "de todo un poco" (AP)
└── Database/
    ├── 01_CreateDatabase.sql
    ├── 02_Tables.sql
    ├── 03_StoredProcedures.sql
    ├── 04_Views.sql
    └── 05_SeedData.sql
```

**Comunicación:** `DistriMax.Web` → HTTP/JSON → `DistriMax.Api` → SQL Server.
El Web **no** accede a la BD directamente... excepto en el módulo de Reportes, que tiene su propio connection string y consulta la BD por ADO.NET (AP-14).

### Puertos locales (IIS Express)

| Proyecto | URL |
|---|---|
| DistriMax.Api | `http://localhost:5301` |
| DistriMax.Web | `http://localhost:5300` |

Ambos proyectos se configuran como *Multiple startup projects*.

---

## 4. Modelo de datos

**Base de datos:** `DistriMaxDB`
**Esquema:** `dbo` (todo en uno, sin separación por módulo — AP)
**Convenciones inconsistentes intencionales:** algunas tablas en plural, otras en singular; PKs `Id`, `IdX` o `X_Id` según el módulo.

### 4.1 Seguridad

| Tabla | Columnas principales |
|---|---|
| `Roles` | IdRol (PK, int identity), Nombre, Activo |
| `Permisos` | IdPermiso (PK), Codigo, Descripcion |
| `RolesPermisos` | IdRol (FK), IdPermiso (FK) |
| `Usuarios` | IdUsuario (PK), Login, Password (**MD5 sin salt** — AP-20), Nombre, Email, IdRol (FK), Token (nvarchar, GUID), TokenExpira (datetime), Activo, FechaCreacion, UltimoAcceso |

Roles semilla: 1 Administrador, 2 Gerencia, 3 Vendedor, 4 Bodeguero, 5 Cartera.

### 4.2 Maestros generales

| Tabla | Columnas principales |
|---|---|
| `Departamentos` | IdDepartamento, Codigo (DANE), Nombre |
| `Ciudades` | IdCiudad, IdDepartamento (FK), Codigo (DANE), Nombre |
| `Parametros` | Clave (PK nvarchar), Valor (nvarchar), Descripcion — ej. `IVA_GENERAL=19`, `RETEFUENTE_PORC=2.5`, `RETEFUENTE_BASE=1344573` (**también quemados en código** — AP-07) |
| `Consecutivos` | Tipo (PK: FAC, PED, OC, REC, ABO), Prefijo, Actual |

### 4.3 Clientes y precios

| Tabla | Columnas principales |
|---|---|
| `ListasPrecios` | IdLista, Nombre (Mayorista, Minorista, Especial), Activa |
| `ListasPreciosDetalle` | IdLista (FK), IdProducto (FK), Precio |
| `Clientes` | IdCliente, TipoDocumento (NIT/CC), NumeroDocumento, DV, RazonSocial, NombreComercial, Direccion, IdCiudad (FK), Telefono, Email, CupoCredito, DiasCredito, IdLista (FK), IdVendedor (FK → Usuarios), Bloqueado, MotivoBloqueo, Activo, FechaCreacion |

### 4.4 Proveedores

| Tabla | Columnas principales |
|---|---|
| `Proveedor` *(singular, AP)* | Proveedor_Id, Nit, DV, RazonSocial, Contacto, Telefono, Email, IdCiudad, DiasPago, Activo |

### 4.5 Productos e inventario

| Tabla | Columnas principales |
|---|---|
| `Categorias` | IdCategoria, Nombre, IdCategoriaPadre (nullable, self-FK) |
| `Productos` | IdProducto, Codigo (único), CodigoBarras, Nombre, Descripcion, IdCategoria, Unidad (UND, CAJA, KG), PorcIva (0/5/19), CostoPromedio, PrecioBase, StockMinimo, Activo |
| `Bodegas` | IdBodega, Nombre, Direccion, Activa |
| `Inventario` | IdBodega + IdProducto (PK compuesta), Cantidad, CantidadReservada |
| `Kardex` | IdKardex, Fecha, IdProducto, IdBodega, TipoMovimiento (ENT_COMPRA, SAL_VENTA, AJU_POS, AJU_NEG, ANU_VENTA, TRASLADO), DocumentoRef, Cantidad, CostoUnitario, SaldoCantidad, SaldoCosto, IdUsuario |
| `AjustesInventario` | IdAjuste, Fecha, IdBodega, IdProducto, Cantidad (+/-), Motivo, IdUsuario |

### 4.6 Compras

| Tabla | Columnas principales |
|---|---|
| `OrdenesCompra` | IdOrden, Numero, Fecha, Proveedor_Id, IdBodega, Estado (`P`/`R`/`C`/`A` — char sin catálogo, AP-08), Subtotal, Iva, Total, Observaciones, IdUsuario |
| `OrdenesCompraDetalle` | IdDetalle, IdOrden, IdProducto, Cantidad, CantidadRecibida, CostoUnitario, PorcIva |
| `Recepciones` | IdRecepcion, Numero, Fecha, IdOrden, IdUsuario |
| `RecepcionesDetalle` | IdDetalle, IdRecepcion, IdProducto, Cantidad, CostoUnitario |

### 4.7 Ventas

| Tabla | Columnas principales |
|---|---|
| `Pedidos` | IdPedido, Numero, Fecha, IdCliente, IdVendedor, IdBodega, Estado (int: 1 Borrador, 2 Aprobado, 3 Facturado, 4 Anulado — magic numbers, AP-08), Subtotal, Descuento, Iva, Total, Observaciones |
| `PedidosDetalle` | IdDetalle, IdPedido, IdProducto, Cantidad, PrecioUnitario, PorcDescuento, PorcIva, Total |

### 4.8 Facturación

| Tabla | Columnas principales |
|---|---|
| `Facturas` | IdFactura, Prefijo, Numero, Fecha, FechaVencimiento, IdCliente, IdPedido, IdVendedor, Subtotal, Descuento, BaseIva, Iva, ReteFuente, Total, Saldo, Estado (`ACTIVA`/`ANULADA` — string, AP-08), MotivoAnulacion, IdUsuario |
| `FacturasDetalle` | IdDetalle, IdFactura, IdProducto, Cantidad, PrecioUnitario, PorcDescuento, PorcIva, ValorIva, Total, CostoUnitario |

### 4.9 Cartera

| Tabla | Columnas principales |
|---|---|
| `Abonos` | IdAbono, Numero, Fecha, IdCliente, Valor, FormaPago (Efectivo, Transferencia, Cheque), Referencia, IdUsuario, Anulado |
| `AbonosDetalle` | IdAbonoDetalle, IdAbono, IdFactura, ValorAplicado |

### 4.10 Auditoría

| Tabla | Columnas principales |
|---|---|
| `LogSistema` | IdLog, Fecha, IdUsuario, Modulo, Accion, Detalle (nvarchar(max), a veces JSON, a veces texto libre — AP) |
| `LogErrores` | IdError, Fecha, Origen (WEB/API), Mensaje, StackTrace, Url |

### 4.11 Vistas

- `vw_CarteraEdades` — saldo por cliente en rangos 0-30, 31-60, 61-90, >90 días.
- `vw_InventarioValorizado` — cantidad × costo promedio por bodega/producto.
- `vw_VentasPorVendedor` — total facturado por vendedor y mes.

---

## 5. Stored Procedures

Mezcla deliberada: algunos SPs tienen lógica de negocio completa (AP-12), otros son CRUD simples, y otros módulos no usan SPs sino SQL desde C#.

| Módulo | Stored Procedures |
|---|---|
| Seguridad | `sp_Login`, `sp_Usuarios_Listar`, `sp_Usuarios_Guardar`, `sp_Usuarios_CambiarPassword` |
| Clientes | `sp_Clientes_Listar`, `sp_Clientes_Obtener`, `sp_Clientes_Guardar` (insert/update en uno, por `@IdCliente = 0`), `sp_Clientes_SaldoCartera` |
| Productos | *(EF6, sin SPs)* |
| Inventario | `sp_Inventario_Consultar`, `sp_Inventario_Ajustar` (actualiza Inventario + Kardex), `sp_Kardex_Consultar` |
| Compras | `sp_OrdenCompra_Guardar`, `sp_OrdenCompra_Listar`, `sp_Recepcion_Procesar` (**recalcula costo promedio, actualiza inventario, kardex y estado de la OC — todo adentro**) |
| Ventas | `sp_Pedido_Guardar`, `sp_Pedido_Aprobar` (valida cupo y reserva stock), `sp_Pedido_Anular` |
| Facturación | `sp_Factura_Generar` (**desde pedido: consecutivo, totales, retención, kardex, inventario, libera reserva — ~200 líneas**), `sp_Factura_Anular`, `sp_Factura_Obtener`, `sp_Facturas_Listar` |
| Cartera | `sp_Abono_Registrar` (aplica a facturas más antiguas primero), `sp_Cartera_EstadoCuenta`, `sp_Clientes_BloquearMorosos` |
| General | `sp_Consecutivo_Siguiente` (con condición de carrera potencial — AP-17), `sp_Log_Insertar` |

---

## 6. Reglas de negocio

### 6.1 Seguridad
- Login con usuario y contraseña; password comparada como hash MD5.
- Al loguear, la API genera un GUID como token, lo guarda en `Usuarios.Token` con expiración de 8 horas y lo devuelve.
- Tres intentos fallidos no bloquean nada (no implementado — deuda).
- Permisos verificados en el MVC con `if` sobre el `IdRol` en cada action (AP-09).

### 6.2 Clientes
- NIT con dígito de verificación calculado (algoritmo DIAN) — la función existe **duplicada** en Web y en API (AP-05).
- Un cliente bloqueado no puede recibir pedidos nuevos.

### 6.3 Inventario
- Stock disponible = `Cantidad − CantidadReservada`.
- Costo promedio ponderado: `(stockActual × costoActual + cantRecibida × costoRecibido) / (stockActual + cantRecibida)`.
- Alerta de stock mínimo en el dashboard.
- Ajustes negativos no pueden dejar inventario en negativo.

### 6.4 Compras
- OC en estado `P` (Pendiente) → recepción parcial pasa a `R`... *(y la completa también — bug conocido de estados, ver 9.2)* → `C` (Cerrada) → `A` (Anulada).
- Recepción no puede exceder lo pendiente de la OC.

### 6.5 Ventas (Pedidos)
- Precio según la lista de precios del cliente; si el producto no está en la lista, usa `PrecioBase`.
- Descuento por volumen por línea (quemado en código, AP-07):
  - ≥ 100 unidades → 5%
  - ≥ 500 unidades → 10%
- Al aprobar: valida que `Total pedido + Saldo cartera ≤ CupoCredito` y que haya stock disponible; reserva el stock.
- Estados: 1 Borrador → 2 Aprobado → 3 Facturado | 4 Anulado.

### 6.6 Facturación
- Solo se factura un pedido aprobado.
- IVA por producto: 0%, 5% o 19%.
- Retención en la fuente: 2.5% sobre el subtotal si supera la base mínima (parámetro). **El cálculo existe en el SP y también en C# para la vista previa, con resultados levemente distintos por redondeo** (AP-06, bug intencional documentado).
- Consecutivo con prefijo `DM` (ej. `DM-000123`).
- Fecha de vencimiento = Fecha + `DiasCredito` del cliente.
- Anulación: devuelve stock, registra kardex `ANU_VENTA`, deja saldo en 0. No se puede anular si tiene abonos.

### 6.7 Cartera
- Abonos se aplican automáticamente a la factura más antigua (FIFO).
- Edades: 0-30, 31-60, 61-90, >90 días.
- Proceso manual "Bloquear morosos": bloquea clientes con saldo > 90 días.

### 6.8 Reportes
- Ventas por vendedor y rango de fechas.
- Inventario valorizado por bodega.
- Cartera por edades.
- Productos más vendidos.
- Exportar a Excel = generar una tabla HTML con `Content-Type: application/vnd.ms-excel` (AP-15).

---

## 7. API — Endpoints (Web API 2)

Autenticación: header `X-Token` validado **manualmente al inicio de cada action** copiando el mismo bloque de código (AP-04). Además existe un `ApiKey` en `Web.config` que algunos controllers validan y otros no.

Respuesta: no hay formato estándar. Algunos endpoints devuelven el objeto, otros `{ ok, mensaje, data }`, otros un `DataTable` serializado (AP-11).

| Controller | Endpoints |
|---|---|
| `AuthController` | `POST api/auth/login`, `POST api/auth/logout` |
| `UsuariosController` | `GET api/usuarios`, `GET api/usuarios/{id}`, `POST api/usuarios`, `PUT api/usuarios/{id}/password` |
| `ClientesController` | `GET api/clientes?buscar=`, `GET api/clientes/{id}`, `POST api/clientes`, `GET api/clientes/{id}/saldo` |
| `ProveedoresController` | `GET api/proveedores`, `GET api/proveedores/{id}`, `POST api/proveedores` |
| `ProductosController` | `GET api/productos?buscar=&categoria=`, `GET api/productos/{id}`, `POST api/productos`, `GET api/productos/{id}/precio?idCliente=` |
| `CategoriasController` | `GET api/categorias`, `POST api/categorias` |
| `InventarioController` | `GET api/inventario?bodega=`, `POST api/inventario/ajuste`, `GET api/inventario/kardex?producto=&desde=&hasta=` |
| `ComprasController` | `GET api/compras`, `GET api/compras/{id}`, `POST api/compras`, `POST api/compras/{id}/recepcion` |
| `PedidosController` | `GET api/pedidos`, `GET api/pedidos/{id}`, `POST api/pedidos`, `POST api/pedidos/{id}/aprobar`, `POST api/pedidos/{id}/anular` |
| `FacturasController` | `GET api/facturas`, `GET api/facturas/{id}`, `POST api/facturas/generar/{idPedido}`, `POST api/facturas/{id}/anular`, `GET api/facturas/preview/{idPedido}` |
| `CarteraController` | `GET api/cartera/edades`, `GET api/cartera/estadocuenta/{idCliente}`, `POST api/cartera/abono`, `POST api/cartera/bloquearmorosos` |
| `GeneralController` | `GET api/general/ciudades?dpto=`, `GET api/general/departamentos`, `GET api/general/bodegas`, `GET api/general/listasprecios` |

### Acceso a datos por módulo (mezcla intencional)

| Módulo | Técnica |
|---|---|
| Seguridad, Clientes, Cartera, Facturación, Compras | ADO.NET + Stored Procedures (`DbHelper.EjecutarSP` que devuelve `DataTable`) |
| Productos, Categorías | EF6 (`DistriMaxEntities`, sin .edmx), contexto instanciado con `new` en cada action |
| Inventario (consultas), General | ADO.NET con **SQL concatenado** (`"... WHERE Nombre LIKE '%" + buscar + "%'"`) — SQL injection, AP-13 |
| Pedidos | Mitad EF6, mitad SP |

---

## 8. Front — ASP.NET MVC 5

### 8.1 Controllers y vistas

| Controller | Vistas principales |
|---|---|
| `AccountController` | Login, Logout |
| `HomeController` | Dashboard (ventas del mes, stock bajo, cartera vencida) |
| `UsuariosController` | Index, Crear, Editar |
| `ClientesController` | Index (DataTables), Crear, Editar, Detalle, EstadoCuenta |
| `ProveedoresController` | Index, Crear, Editar |
| `ProductosController` | Index, Crear, Editar |
| `InventarioController` | Index, Ajuste, Kardex |
| `ComprasController` | Index, Crear, Detalle, Recepcion |
| `PedidosController` | Index, Crear (carrito en `Session`), Detalle |
| `FacturasController` | Index, Detalle, Imprimir (vista HTML para imprimir) |
| `CarteraController` | Edades, RegistrarAbono, EstadoCuenta |
| `ReportesController` | Ventas, Inventario, Cartera, TopProductos, ExportarExcel |

### 8.2 Características "legacy" del front
- Usuario logueado y token guardados en `Session["Usuario"]` y `Session["Token"]`.
- Cada action valida sesión manualmente (`if (Session["Usuario"] == null) return RedirectToAction("Login","Account");`) — sin filtro global (AP-09).
- `ApiHelper` estático que crea `new HttpClient()` en cada llamada (AP-03) y usa `.Result` (AP-16).
- `ViewBag` para pasar listas a combos y mensajes.
- JS inline en las vistas con concatenación de HTML para armar tablas.
- Layout con menú armado con `if` por rol dentro del `_Layout.cshtml`.
- Mensajes de éxito/error vía `TempData["Mensaje"]`.

---

## 9. Catálogo de deuda técnica (anti-patrones intencionales)

Cada anti-patrón se marca en el código con un comentario `// AP-XX` para ubicarlo después en la refactorización.

### 9.1 Anti-patrones

| ID | Anti-patrón | Dónde |
|---|---|---|
| AP-01 | Fat controllers (lógica + datos + validación en la action) | API y Web, especialmente Pedidos y Facturas |
| AP-02 | Sin inyección de dependencias, `new` por todas partes | Toda la solución |
| AP-03 | `new HttpClient()` por request | `ApiHelper` (Web) |
| AP-04 | Validación de token copiada y pegada en cada action | Controllers API |
| AP-05 | Lógica duplicada entre proyectos (DV del NIT, formato moneda) | Web `Helpers` y API `Helpers` |
| AP-06 | Cálculos de negocio duplicados en SP y en C# con diferencias | Retención en la fuente |
| AP-07 | Valores quemados (IVA, retención, descuentos) aunque existen en `Parametros` | `CalculosHelper`, `PedidosController` |
| AP-08 | Magic numbers / strings para estados sin enums ni catálogos | Pedidos (int), OC (char), Facturas (string) |
| AP-09 | Autorización por `if (rol == 3)` disperso | Controllers Web y `_Layout` |
| AP-10 | Clases `static` "Dios": `Utils`, `Helper` | `DistriMax.Common.Utils`, `Api.Helpers.Utils` |
| AP-11 | Respuestas de API inconsistentes | Controllers API |
| AP-12 | Lógica de negocio pesada en stored procedures | `sp_Factura_Generar`, `sp_Recepcion_Procesar` |
| AP-13 | SQL concatenado (SQL injection) | Inventario, General |
| AP-14 | El front accede directo a la BD | `ReportesController` (Web) |
| AP-15 | "Excel" que es HTML con otro content-type | Reportes |
| AP-16 | Sync over async (`.Result`, `.Wait()`) | `ApiHelper` |
| AP-17 | Consecutivos sin bloqueo adecuado (race condition) | `sp_Consecutivo_Siguiente` |
| AP-18 | `try/catch` vacíos o que solo hacen `return null` | Varios |
| AP-19 | Connection strings y ApiKey en texto plano, duplicados | `Web.config` de ambos proyectos |
| AP-20 | Passwords MD5 sin salt | `Usuarios`, `AuthController` |
| AP-21 | Método "Dios" de 300+ líneas | `FacturasController.Generar` (Web) / `PedidosController.Guardar` (API) |
| AP-22 | DTOs usados como entidades y ViewModels a la vez | `DistriMax.Common.DTOs` |
| AP-23 | Uso de `Session` para estado de negocio (carrito del pedido) | `PedidosController` (Web) |
| AP-24 | Logging casero que escribe a BD de forma síncrona y silencia fallos | `LogHelper` |
| AP-25 | Cero pruebas automatizadas | Solución completa |
| AP-26 | Nombres inconsistentes (español/inglés, singular/plural, prefijos) | BD y código |
| AP-27 | `DataTable` viajando hasta el controller y mapeado a mano | API (ADO.NET) |
| AP-28 | EF6 contexto sin `using` / sin dispose | Productos, Categorías |

### 9.2 Bugs conocidos (intencionales y documentados)

| ID | Bug |
|---|---|
| BUG-01 | Diferencia de redondeo en retención entre vista previa (C#) y factura (SP). |
| BUG-02 | Recepción completa de OC deja estado `R` en lugar de `C` en ciertos casos. |
| BUG-03 | Si el token expira, el front muestra error genérico en lugar de redirigir al login. |

> Los bugs deben ser **sutiles**, no impedir el uso del sistema.

---

## 10. Configuración

### `DistriMax.Api/Web.config`
```xml
<connectionStrings>
  <add name="DistriMaxDB"
       connectionString="Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=DistriMaxDB;Integrated Security=True"
       providerName="System.Data.SqlClient" />
</connectionStrings>
<appSettings>
  <add key="ApiKey" value="DM-2019-SECRET-KEY" />
  <add key="TokenHorasExpiracion" value="8" />
</appSettings>
```

### `DistriMax.Web/Web.config`
```xml
<connectionStrings>
  <!-- usado solo por Reportes (AP-14) -->
  <add name="DistriMaxDB" connectionString="Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=DistriMaxDB;Integrated Security=True" providerName="System.Data.SqlClient" />
</connectionStrings>
<appSettings>
  <add key="UrlApi" value="http://localhost:5301/" />
  <add key="ApiKey" value="DM-2019-SECRET-KEY" />
</appSettings>
```

> Si se usa SQL Express en lugar de LocalDB: `Data Source=.\SQLEXPRESS`.

---

## 11. Datos semilla

| Entidad | Cantidad aprox. |
|---|---|
| Usuarios | 6 (admin, gerente, 2 vendedores, bodeguero, cartera) |
| Departamentos / Ciudades | Principales de Colombia (~10 dptos, ~30 ciudades) |
| Categorías | 8 (con subcategorías) |
| Productos | 100 (abarrotes, aseo, bebidas, papelería) con IVA mixto |
| Bodegas | 3 (Bogotá Principal, Medellín, Cali) |
| Clientes | 50 (con NIT válido y DV correcto) |
| Proveedores | 10 |
| Listas de precios | 3 |
| Órdenes de compra históricas | ~30 |
| Facturas históricas | ~200 (últimos 6 meses, para que reportes y cartera tengan datos) |
| Abonos | ~120 |

### Credenciales de prueba

| Usuario | Password | Rol |
|---|---|---|
| admin | admin123 | Administrador |
| gerente | gerente123 | Gerencia |
| vendedor1 | vend123 | Vendedor |
| vendedor2 | vend123 | Vendedor |
| bodega | bodega123 | Bodeguero |
| cartera | cartera123 | Cartera |

---

## 12. Ejecución local

1. Instalar Visual Studio 2022 con workload **ASP.NET and web development** y componente **.NET Framework 4.8 targeting pack**.
2. Verificar SQL Server LocalDB: `sqllocaldb info` → debe aparecer `MSSQLLocalDB`.
3. Ejecutar los scripts de `/Database` **en orden** (01 → 05) desde SSMS o Azure Data Studio.
4. Abrir `DistriMax.sln`, restaurar paquetes NuGet.
5. Configurar *Multiple startup projects*: `DistriMax.Api` y `DistriMax.Web` en **Start**.
6. Verificar puertos (5301 API, 5300 Web) en propiedades de cada proyecto → *Web*.
7. F5 → login con `admin / admin123`.

### Checklist de humo
- [ ] Login funciona y muestra dashboard
- [ ] Listar y crear cliente
- [ ] Listar productos (EF6)
- [ ] Crear OC y recepcionarla → inventario y kardex actualizados
- [ ] Crear pedido, aprobarlo → stock reservado
- [ ] Facturar pedido → consecutivo, inventario descontado
- [ ] Registrar abono → saldo de factura actualizado
- [ ] Reporte de cartera por edades con datos
- [ ] Exportar reporte a "Excel"

---

## 13. Plan de construcción

| Fase | Entregable | Estado |
|---|---|---|
| 0 | Este documento | ✅ |
| 1 | Scripts de BD (tablas, SPs, vistas, seed) | ✅ |
| 2 | Solución base: 3 proyectos, Web.config, `DbHelper`, `ApiHelper`, contexto EF6 | ✅ |
| 3 | Seguridad (login, token, sesión, layout por rol) + administración de usuarios | ✅ |
| 4 | Maestros: Clientes, Proveedores, Productos, Categorías (solo API), General | ✅ |
| 5 | Inventario (consulta, ajustes, kardex) | ⬜ |
| 6 | Compras y recepciones | ⬜ |
| 7 | Pedidos | ⬜ |
| 8 | Facturación | ⬜ |
| 9 | Cartera | ⬜ |
| 10 | Reportes y dashboard (dashboard de inicio ya hecho) | 🟡 |
| 11 | Prueba local completa (checklist de humo) | ⬜ |
| 12 | Inventario de deuda técnica → inicio de refactor/migración | ⬜ |

---

## 14. Desviaciones respecto al plan inicial

- **EF6 sin .edmx:** el `.edmx` lo genera el diseñador de Visual Studio y no se puede escribir a mano de forma confiable, así que Productos y Categorías usan un `DbContext` con entidades mapeadas con `[Table]`/`[Key]` (lo que VS genera con "Code First from Database"). Sigue siendo EF6 y sigue mezclado con ADO.NET, que es lo importante para el ejercicio.
- **Sin paquete Roslyn en el front:** las vistas Razor compilan con el compilador del framework (C# 5). Por eso las vistas no usan `$""`, `?.` ni `nameof`. Es otra limitación típica de proyectos viejos.
- **Front sin bundling:** las librerías se cargan desde CDN en el `_Layout`, todas en el `<head>`.
- **Datos semilla generados:** el `05_SeedData.sql` lo genera una simulación (no se edita a mano) con fechas relativas a `GETDATE()`. Inventario, kardex, costos promedio y cartera son consistentes entre sí; `99_Verificacion.sql` lo comprueba.
- **Detalle de documentos como XML:** los SPs de OC, recepciones y pedidos reciben el detalle como `XML` (`<items><item .../></items>`), estilo de la época, en lugar de table-valued parameters.
- **Anti-patrones extra que aparecieron:** N+1 en el listado de productos (EF + una consulta ADO por producto), filtro de "mis clientes" del vendedor hecho en el front, endpoint de saldo de clientes sin validar token, errores devueltos con `200 OK` en productos y la tabla `Permisos` que existe pero nadie usa.

## 15. Futuro: objetivos de refactorización y migración (referencia)

No se implementa ahora; sirve para orientar la fase posterior.

- Migrar a **.NET 8/9**: ASP.NET Core MVC (o Razor Pages / Blazor) + ASP.NET Core Web API.
- Introducir arquitectura por capas o Clean Architecture, DI nativa, `IHttpClientFactory`.
- Reemplazar ADO.NET/EDMX por EF Core (o Dapper) con repositorios donde aporte.
- Sacar lógica de los SPs hacia el dominio, con pruebas unitarias.
- JWT + ASP.NET Core Identity, hashing con PBKDF2/BCrypt.
- Respuestas estandarizadas (ProblemDetails), validación con FluentValidation.
- Logging estructurado (Serilog / OpenTelemetry), configuración por `appsettings` + secretos.
- Estrategia de migración incremental (Strangler Fig con YARP) vs big-bang.
