create or replace package body dbms_application_info_wa as
--
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : dbms_application_info_wa(body)
 * Description      : SR 3-9937910241����񋟂��ꂽ�s���S�ȕ��������O����p�b�P�[�W
 * Version          : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/03/27    1.0   T.Kitagawa       �V�K�쐬(E_�{�ғ�_12973�Ή�)
 *
 *****************************************************************************************/
--
procedure set_module(module_name varchar2, action_name varchar2) is
va varchar2(64);
begin
va := substrb(action_name,1,32);
sys.dbms_application_info.set_module(module_name, va);
end set_module;

procedure set_action(action_name varchar2) is
va varchar2(64);
begin
va := substrb(action_name,1,32);
sys.dbms_application_info.set_action(va);
end set_action;

procedure read_module(module_name out varchar2, action_name out varchar2) is
begin
sys.dbms_application_info.read_module(module_name, action_name);
end read_module;

procedure set_client_info(client_info varchar2) is
begin
sys.dbms_application_info.set_client_info(client_info);
end set_client_info;

procedure read_client_info(client_info out varchar2) is
begin
sys.dbms_application_info.read_client_info(client_info);
end read_client_info;

procedure set_session_longops(rindex      in out pls_integer,
                              slno        in out pls_integer,
                              op_name     in varchar2 default null,
                              target      in pls_integer default 0,
                              context     in pls_integer default 0,
                              sofar       in number default 0,
                              totalwork   in number default 0,
                              target_desc in varchar2
                                             default 'unknown target',
                              units       in varchar2 default null) is
begin
sys.dbms_application_info.set_session_longops(
  rindex, slno, op_name, target, context, sofar, totalwork,
  target_desc, units);
end set_session_longops;

end dbms_application_info_wa;
/
