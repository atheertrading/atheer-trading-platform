declare module "node:http" {
  export interface IncomingMessage {
    method?: string;
    url?: string;
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
  export interface Process {
    on(event: "SIGINT" | "SIGTERM", listener: () => void): this;
    cwd(): string;
    exitCode?: number;
  }
  const process: Process;
  export default process;
  export const env: Readonly<Record<string, string | undefined>>;
}

declare module "node:crypto" {
  export interface Hash {
    update(data: string, inputEncoding?: "utf8"): Hash;
    digest(encoding: "hex"): string;
  }
  export function createHash(algorithm: string): Hash;
}

declare module "node:fs/promises" {
  export function readdir(path: string): Promise<string[]>;
  export function readFile(path: string, encoding: "utf8"): Promise<string>;
}

declare module "node:path" {
  export function resolve(...paths: string[]): string;
  export function dirname(path: string): string;
}

declare module "node:url" {
  export function fileURLToPath(url: string): string;
}
