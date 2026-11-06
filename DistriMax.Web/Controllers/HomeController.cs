using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Mvc;

namespace DistriMax.Web.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");

            // AP-14: el front consulta la base de datos directamente, saltándose la API
            string cs = ConfigurationManager.ConnectionStrings["DistriMaxDB"].ConnectionString;
            SqlConnection cn = new SqlConnection(cs);
            cn.Open();

            SqlCommand cmd = new SqlCommand("SELECT ISNULL(SUM(Total), 0) FROM Facturas WHERE Estado = 'ACTIVA' AND Fecha >= DATEADD(DAY, -30, GETDATE())", cn);
            ViewBag.Ventas30 = Convert.ToDecimal(cmd.ExecuteScalar());

            cmd.CommandText = "SELECT COUNT(*) FROM Facturas WHERE Estado = 'ACTIVA' AND Fecha >= DATEADD(DAY, -30, GETDATE())";
            ViewBag.Facturas30 = Convert.ToInt32(cmd.ExecuteScalar());

            cmd.CommandText = "SELECT ISNULL(SUM(Saldo), 0) FROM Facturas WHERE Estado = 'ACTIVA' AND Saldo > 0 AND FechaVencimiento < GETDATE()";
            ViewBag.CarteraVencida = Convert.ToDecimal(cmd.ExecuteScalar());

            cmd.CommandText = "SELECT ISNULL(SUM(Saldo), 0) FROM Facturas WHERE Estado = 'ACTIVA' AND Saldo > 0";
            ViewBag.CarteraTotal = Convert.ToDecimal(cmd.ExecuteScalar());

            cmd.CommandText = "SELECT COUNT(*) FROM Pedidos WHERE Estado IN (1, 2)";
            ViewBag.PedidosPendientes = Convert.ToInt32(cmd.ExecuteScalar());

            cmd.CommandText = "SELECT COUNT(*) FROM Clientes WHERE Bloqueado = 1";
            ViewBag.ClientesBloqueados = Convert.ToInt32(cmd.ExecuteScalar());

            cmd.CommandText = "SELECT COUNT(*) FROM Inventario i INNER JOIN Productos p ON p.IdProducto = i.IdProducto "
                + "WHERE p.Activo = 1 AND i.Cantidad - i.CantidadReservada <= p.StockMinimo";
            ViewBag.TotalStockBajo = Convert.ToInt32(cmd.ExecuteScalar());

            cmd.CommandText = "SELECT TOP 10 b.Nombre AS Bodega, p.Codigo, p.Nombre, i.Cantidad - i.CantidadReservada AS Disponible, p.StockMinimo "
                + "FROM Inventario i INNER JOIN Productos p ON p.IdProducto = i.IdProducto INNER JOIN Bodegas b ON b.IdBodega = i.IdBodega "
                + "WHERE p.Activo = 1 AND i.Cantidad - i.CantidadReservada <= p.StockMinimo "
                + "ORDER BY (i.Cantidad - i.CantidadReservada) / NULLIF(p.StockMinimo, 0)";
            DataTable dtStock = new DataTable();
            new SqlDataAdapter(cmd).Fill(dtStock);
            ViewBag.StockBajo = dtStock;

            cmd.CommandText = "SELECT TOP 5 f.Prefijo + '-' + CAST(f.Numero AS VARCHAR(10)) AS Factura, f.Fecha, c.RazonSocial, f.Total "
                + "FROM Facturas f INNER JOIN Clientes c ON c.IdCliente = f.IdCliente WHERE f.Estado = 'ACTIVA' ORDER BY f.Fecha DESC";
            DataTable dtUltimas = new DataTable();
            new SqlDataAdapter(cmd).Fill(dtUltimas);
            ViewBag.UltimasFacturas = dtUltimas;

            cn.Close();
            return View();
        }
    }
}
