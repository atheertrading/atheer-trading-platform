declare module "node:http" {
  export interface IncomingMessage {
    method?: string;
    url?: string;
  }
  export interface ServerResponse {
    statusCode: number;
    setHeader(name: string, value: string): void;
    end(body?: string): void;
  }
  export interface Server {
    listen(port: number, hostname: string, callback?: () => void): this;
    close(callback?: (error?: Error) => void): this;
    address(): { port: number } | string | null;
  }
  export function createServer(
    listener: (request: IncomingMessage, response: ServerResponse) => void,
  ): Server;
}

declare module "node:process" {
  export interface Process {
    on(event: "SIGINT" | "SIGTERM", listener: () => void): this;
  }
  const process: Process;
  export default process;
  export const env: Readonly<Record<string, string | undefined>>;
}
