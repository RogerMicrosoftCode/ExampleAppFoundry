import { Logger } from './logger';

describe('Logger', () => {
  let consoleSpy: {
    log: jest.SpyInstance;
    error: jest.SpyInstance;
    warn: jest.SpyInstance;
    debug: jest.SpyInstance;
  };

  beforeEach(() => {
    consoleSpy = {
      log: jest.spyOn(console, 'log').mockImplementation(),
      error: jest.spyOn(console, 'error').mockImplementation(),
      warn: jest.spyOn(console, 'warn').mockImplementation(),
      debug: jest.spyOn(console, 'debug').mockImplementation(),
    };
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('should log info messages', () => {
    Logger.info('Test message');
    expect(consoleSpy.log).toHaveBeenCalled();
    expect(consoleSpy.log.mock.calls[0][0]).toContain('[INFO]');
    expect(consoleSpy.log.mock.calls[0][0]).toContain('Test message');
  });

  it('should log error messages', () => {
    Logger.error('Error message');
    expect(consoleSpy.error).toHaveBeenCalled();
    expect(consoleSpy.error.mock.calls[0][0]).toContain('[ERROR]');
    expect(consoleSpy.error.mock.calls[0][0]).toContain('Error message');
  });

  it('should log warn messages', () => {
    Logger.warn('Warning message');
    expect(consoleSpy.warn).toHaveBeenCalled();
    expect(consoleSpy.warn.mock.calls[0][0]).toContain('[WARN]');
    expect(consoleSpy.warn.mock.calls[0][0]).toContain('Warning message');
  });

  it('should log debug messages when DEBUG is true', () => {
    process.env.DEBUG = 'true';
    Logger.debug('Debug message');
    expect(consoleSpy.debug).toHaveBeenCalled();
    expect(consoleSpy.debug.mock.calls[0][0]).toContain('[DEBUG]');
    expect(consoleSpy.debug.mock.calls[0][0]).toContain('Debug message');
    delete process.env.DEBUG;
  });

  it('should not log debug messages when DEBUG is not set', () => {
    Logger.debug('Debug message');
    expect(consoleSpy.debug).not.toHaveBeenCalled();
  });
});
