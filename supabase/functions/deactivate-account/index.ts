import { createClient } from "npm:@supabase/supabase-js@2.95.0";
const corsHeaders = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
Deno.serve(async (req: Request) => {
 if(req.method==="OPTIONS") return new Response("ok",{headers:corsHeaders});
 if(req.method!=="POST") return Response.json({error:"METHOD_NOT_ALLOWED"},{status:405,headers:corsHeaders});
 const authorization=req.headers.get("Authorization");
 if(!authorization?.startsWith("Bearer ")) return Response.json({error:"AUTH_REQUIRED"},{status:401,headers:corsHeaders});
 try {
  const url=Deno.env.get("SUPABASE_URL"), anonKey=Deno.env.get("SUPABASE_ANON_KEY");
  if(!url||!anonKey) throw new Error("FUNCTION_ENVIRONMENT_NOT_CONFIGURED");
  const supabase=createClient(url,anonKey,{global:{headers:{Authorization:authorization}},auth:{persistSession:false,autoRefreshToken:false}});
  const token=authorization.slice("Bearer ".length);
  const {data,error:authError}=await supabase.auth.getUser(token);
  if(authError||!data.user) return Response.json({error:"INVALID_SESSION"},{status:401,headers:corsHeaders});
  const {error:deactivateError}=await supabase.rpc("deactivate_my_account");
  if(deactivateError) return Response.json({error:"DEACTIVATION_FAILED"},{status:400,headers:corsHeaders});
  const revoked=await fetch(`${url}/auth/v1/logout?scope=global`,{method:"POST",headers:{apikey:anonKey,Authorization:authorization}});
  if(!revoked.ok) return Response.json({deactivated:true,refresh_sessions_revoked:false,code:"SESSION_REVOCATION_PENDING"},{status:202,headers:corsHeaders});
  return Response.json({deactivated:true,refresh_sessions_revoked:true},{status:200,headers:{...corsHeaders,"Content-Type":"application/json"}});
 } catch { return Response.json({error:"INTERNAL_ERROR"},{status:500,headers:corsHeaders}); }
});