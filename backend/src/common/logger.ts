/**
 * Simple console logger
 */
export class Logger {
  private readonly namespace: string;

  public constructor(namespace?: string) {
    this.namespace = namespace ? `[${namespace}]` : "";
  }

  public log(...args: unknown[]): void {
    console.log(...this.fmt(args));
  }

  public info(...args: unknown[]): void {
    console.info(...this.fmt(args));
  }

  public warn(...args: unknown[]): void {
    console.warn(...this.fmt(args));
  }

  public error(...args: unknown[]): void {
    console.error(...this.fmt(args));
  }

  public debug(...args: unknown[]): void {
    console.debug(...this.fmt(args));
  }

  public trace(...args: unknown[]): void {
    console.trace(...this.fmt(args));
  }

  private fmt(args: unknown[]): unknown[] {
    return this.namespace ? [this.namespace, ...args] : args;
  }
}
