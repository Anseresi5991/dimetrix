namespace DistriMax.Common.DTOs
{
    public class ProductoDTO
    {
        public int IdProducto { get; set; }
        public string Codigo { get; set; }
        public string CodigoBarras { get; set; }
        public string Nombre { get; set; }
        public string Descripcion { get; set; }
        public int IdCategoria { get; set; }
        public string Categoria { get; set; }
        public string Unidad { get; set; }
        public decimal PorcIva { get; set; }
        public decimal CostoPromedio { get; set; }
        public decimal PrecioBase { get; set; }
        public decimal StockMinimo { get; set; }
        public bool Activo { get; set; }
        public decimal StockTotal { get; set; }
    }

    public class CategoriaDTO
    {
        public int IdCategoria { get; set; }
        public string Nombre { get; set; }
        public int? IdCategoriaPadre { get; set; }
        public string CategoriaPadre { get; set; }
        public bool Activa { get; set; }
    }
}
