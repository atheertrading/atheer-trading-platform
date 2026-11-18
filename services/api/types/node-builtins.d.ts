declare module "node:http" {
  export interface IncomingMessage extends AsyncIterable<Uint8Array> {
    method?: string;
    url?: string;
    headers: Readonly<Record<string, string | string[] | undefined>>;
  }
  export interface ServerResponse {
    statusCode: number;
    readonly destroyed: boolean;
    setHeader(name: string, value: string): void;
    writeHead(statusCode: number, headers?: Readonly<Record<string, string>>): this;
    write(body: string): boolean;
    on(event: "close", listener: () => void): this;
    end(body?: string): void;
  }
  export interface Server {
    listen(port: number, hostname: string, callback?: () => void): this;
    close(callback?: (error?: Error) => void): this;
    closeAllConnections(): void;
    address(): { port: number } | string | null;
  }
  export function createServer(
    listener: (request: IncomingMessage, response: ServerResponse) => void,
  ): Server;
}

declare module "node:process" {
  export interface WritableStream {
    write(chunk: string | Uint8Array): boolean;
  }
  export interface Process {
    stdin: AsyncIterable<Uint8Array>;
    stdout: WritableStream;
    exitCode: number | undefined;
    exit(code?: number): never;
    on(event: "SIGINT" | "SIGTERM", listener: () => void): this;
  }
  const process: Process;
  export default process;
  export const env: Readonly<Record<string, string | undefined>>;
}


declare module "node:buffer" {
  export class Buffer extends Uint8Array {
    static alloc(size: number): Buffer;
    static from(value: string | Uint8Array, encoding?: string): Buffer;
    static concat(list: readonly Uint8Array[], totalLength?: number): Buffer;
    static byteLength(value: string, encoding?: string): number;
    toString(encoding?: string): string;
  }
}

declare module "node:fs/promises" {
  export interface Stats {
    readonly mode: number;
    isDirectory(): boolean;
  }
  export function chmod(path: string, mode: number): Promise<void>;
  export function lstat(path: string): Promise<Stats>;
  export function stat(path: string): Promise<Stats>;
  export function unlink(path: string): Promise<void>;
}

declare module "node:path" {
  export function dirname(path: string): string;
}

declare module "node:net" {
  import type { Buffer } from "node:buffer";

  export interface Socket {
    readonly destroyed: boolean;
    setNoDelay(noDelay?: boolean): this;
    setTimeout(timeout: number, callback?: () => void): this;
    on(event: "close" | "end", listener: () => void): this;
    on(event: "error", listener: (error: Error) => void): this;
    on(event: "data", listener: (chunk: Buffer) => void): this;
    end(data?: string | Uint8Array): this;
    destroy(): this;
  }

  export interface Server {
    once(event: "error", listener: (error: Error) => void): this;
    removeListener(event: "error", listener: (error: Error) => void): this;
    listen(path: string, callback?: () => void): this;
    close(callback?: (error?: Error) => void): this;
  }

  export function createServer(listener: (socket: Socket) => void): Server;
}
