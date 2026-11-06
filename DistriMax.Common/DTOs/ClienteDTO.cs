using System;

namespace DistriMax.Common.DTOs
{
    public class ClienteDTO
    {
        public int IdCliente { get; set; }
        public string TipoDocumento { get; set; }
        public string NumeroDocumento { get; set; }
        public string DV { get; set; }
        public string RazonSocial { get; set; }
        public string NombreComercial { get; set; }
        public string Direccion { get; set; }
        public int? IdCiudad { get; set; }
        public string Ciudad { get; set; }
        public int? IdDepartamento { get; set; }
        public string Departamento { get; set; }
        public string Telefono { get; set; }
        public string Email { get; set; }
        public decimal CupoCredito { get; set; }
        public int DiasCredito { get; set; }
        public int? IdLista { get; set; }
        public string ListaPrecios { get; set; }
        public int? IdVendedor { get; set; }
        public string Vendedor { get; set; }
        public bool Bloqueado { get; set; }
        public string MotivoBloqueo { get; set; }
        public bool Activo { get; set; }
        public DateTime? FechaCreacion { get; set; }
        public decimal Saldo { get; set; }
    }

    public class SaldoClienteDTO
    {
        public int IdCliente { get; set; }
        public decimal CupoCredito { get; set; }
        public decimal Saldo { get; set; }
        public decimal Disponible { get; set; }
        public decimal SaldoVencido { get; set; }
    }
}
