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
    on(event: "SIGINT" | "SIGTERM", listener: () => void): this;
  }
  const process: Process;
  export default process;
  export const env: Readonly<Record<string, string | undefined>>;
}
