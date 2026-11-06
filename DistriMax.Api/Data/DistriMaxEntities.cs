using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data.Entity;

namespace DistriMax.Api.Data
{
    // EF6 "Code First from Database": solo mapea Productos y Categorías.
    // El resto de la app usa ADO.NET (mezcla intencional).
    public class DistriMaxEntities : DbContext
    {
        static DistriMaxEntities()
        {
            Database.SetInitializer<DistriMaxEntities>(null);
        }

        public DistriMaxEntities() : base("name=DistriMaxDB")
        {
            this.Configuration.ProxyCreationEnabled = false;
            this.Configuration.LazyLoadingEnabled = false;
        }

        public DbSet<Producto> Productos { get; set; }
        public DbSet<Categoria> Categorias { get; set; }
    }

    [Table("Productos")]
    public class Producto
    {
        [Key]
        public int IdProducto { get; set; }
        public string Codigo { get; set; }
        public string CodigoBarras { get; set; }
        public string Nombre { get; set; }
        public string Descripcion { get; set; }
        public int IdCategoria { get; set; }
        public string Unidad { get; set; }
        public decimal PorcIva { get; set; }
        public decimal CostoPromedio { get; set; }
        public decimal PrecioBase { get; set; }
        public decimal StockMinimo { get; set; }
        public bool Activo { get; set; }
    }

    [Table("Categorias")]
    public class Categoria
    {
        [Key]
        public int IdCategoria { get; set; }
        public string Nombre { get; set; }
        public int? IdCategoriaPadre { get; set; }
        public bool Activa { get; set; }
    }
}
