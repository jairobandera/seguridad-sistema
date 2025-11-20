import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { UsuarioRepository } from "./usuario.repository";
import { CrearUsuarioDTO, ActualizarUsuarioDTO } from "./usuario.dto";
import { SesionService } from "../sesiones/sesion.service";

export class UsuarioService {
  private repo = new UsuarioRepository();
  private sesionService = new SesionService();

  async crearUsuario(data: CrearUsuarioDTO) {
    const existe = await this.repo.buscarPorEmail(data.email);
    if (existe) throw new Error("El email ya está registrado.");

    const passwordHash = await bcrypt.hash(data.password, 10);

    const usuario = await this.repo.crear({
      ...data,
      passwordHash,
    });

    return usuario;
  }

  async login(email: string, password: string) {
    const usuario = await this.repo.buscarPorEmail(email);
    if (!usuario) throw new Error("Credenciales inválidas.");

    const valido = await bcrypt.compare(password, usuario.passwordHash);
    if (!valido) throw new Error("Credenciales inválidas.");

    const token = jwt.sign(
      {
        id: usuario.id,
        rol: usuario.rol,
      },
      process.env.JWT_SECRET!,
      { expiresIn: "24h" }
    );

    // ⭐ registrar sesión
    await this.sesionService.crearSesion({
      usuarioId: usuario.id,
      jwtToken: token,
      ip: "0.0.0.0", // luego se reemplaza por req.ip
      dispositivo: "API", // luego se reemplaza por user-agent
    });

    return { usuario, token };
  }

  obtenerTodos() {
    return this.repo.obtenerTodos();
  }

  actualizar(id: number, data: ActualizarUsuarioDTO) {
    return this.repo.actualizar(id, data);
  }

  eliminar(id: number) {
    return this.repo.eliminar(id);
  }

  obtenerPorId(id: number) {
    return this.repo.obtenerPorId(id);
  }
}
