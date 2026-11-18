declare module "node:crypto" {
  export function timingSafeEqual(left: Uint8Array, right: Uint8Array): boolean;
}
