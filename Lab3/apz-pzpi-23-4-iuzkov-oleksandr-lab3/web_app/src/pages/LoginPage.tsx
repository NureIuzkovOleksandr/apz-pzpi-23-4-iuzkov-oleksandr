import { useState, FormEvent, ChangeEvent } from 'react';
import { LocaleCode } from '../types';
import { t } from '../i18n';

interface LoginPageProps {
  locale: LocaleCode;
  onLogin: (email: string, password: string) => Promise<void>;
  onRegister: (username: string, email: string, password: string) => Promise<void>;
  loading: boolean;
  error: string;
}

export default function LoginPage({ locale, onLogin, onRegister, loading, error }: LoginPageProps) {
  const [isRegister, setIsRegister] = useState(false);
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [formError, setFormError] = useState('');

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!email || !password || (isRegister && !username)) {
      setFormError(t(locale, 'requiredField'));
      return;
    }
    if (isRegister && password.length < 8) {
      setFormError(locale === 'uk' 
        ? 'Пароль має містити щонайменше 8 символів' 
        : 'Password must be at least 8 characters long'
      );
      return;
    }
    setFormError('');
    if (isRegister) {
      await onRegister(username, email, password);
    } else {
      await onLogin(email, password);
    }
  };

  return (
    <div className="card auth-card">
      <h2 style={{ textAlign: 'center', marginBottom: '1.5rem', color: '#134e6f' }}>
        {isRegister ? t(locale, 'register') : t(locale, 'signIn')}
      </h2>
      <form onSubmit={submit}>
        {isRegister && (
          <>
            <label>{t(locale, 'username')}</label>
            <input 
              value={username} 
              onChange={(event: ChangeEvent<HTMLInputElement>) => setUsername(event.target.value)} 
              type="text" 
              placeholder={locale === 'uk' ? 'Введіть імʼя користувача' : 'Enter username'}
            />
          </>
        )}
        
        <label>{t(locale, 'email')}</label>
        <input 
          value={email} 
          onChange={(event: ChangeEvent<HTMLInputElement>) => setEmail(event.target.value)} 
          type="email" 
          placeholder="example@domain.com"
        />
        
        <label>{t(locale, 'password')}</label>
        <input 
          value={password} 
          onChange={(event: ChangeEvent<HTMLInputElement>) => setPassword(event.target.value)} 
          type="password" 
          placeholder={locale === 'uk' ? 'Мінімум 8 символів' : 'Minimum 8 characters'}
        />
        
        {(formError || error) && <div className="error">{formError || error}</div>}
        
        <button 
          type="submit" 
          disabled={loading} 
          style={{ width: '100%', marginTop: '1.5rem', transition: 'all 0.2s' }}
        >
          {loading ? t(locale, 'loading') : (isRegister ? t(locale, 'createAccount') : t(locale, 'signIn'))}
        </button>
      </form>
      
      <div style={{ marginTop: '1.5rem', textAlign: 'center', fontSize: '0.95rem' }}>
        {isRegister ? (
          <>
            {locale === 'uk' ? 'Вже є акаунт? ' : 'Already have an account? '}
            <a 
              href="#" 
              onClick={(e) => { e.preventDefault(); setIsRegister(false); setFormError(''); }} 
              style={{ fontWeight: '700', color: '#1fb59a' }}
            >
              {t(locale, 'signIn')}
            </a>
          </>
        ) : (
          <>
            {locale === 'uk' ? 'Немає акаунту? ' : "Don't have an account? "}
            <a 
              href="#" 
              onClick={(e) => { e.preventDefault(); setIsRegister(true); setFormError(''); }} 
              style={{ fontWeight: '700', color: '#1fb59a' }}
            >
              {t(locale, 'register')}
            </a>
          </>
        )}
      </div>
    </div>
  );
}


