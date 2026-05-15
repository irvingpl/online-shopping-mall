import type { AuthTokens } from '@mall/shared';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';

import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(private readonly jwtService: JwtService) {}

  async register(dto: RegisterDto): Promise<{ message: string }> {
    const _hashedPassword = await bcrypt.hash(dto.password, 12);
    // TODO: PrismaService로 사용자 저장
    return { message: '회원가입이 완료되었습니다.' };
  }

  async login(dto: LoginDto): Promise<AuthTokens> {
    // TODO: DB에서 사용자 조회 후 비밀번호 검증
    const payload = { sub: 'user-id', email: dto.email };
    const accessToken = this.jwtService.sign(payload, { expiresIn: '1h' });
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });
    return { accessToken, refreshToken };
  }

  async validateToken(token: string): Promise<{ sub: string; email: string }> {
    try {
      return this.jwtService.verify(token);
    } catch {
      throw new UnauthorizedException('유효하지 않은 토큰입니다.');
    }
  }
}
