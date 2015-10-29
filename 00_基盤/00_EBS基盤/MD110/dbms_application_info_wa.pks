create or replace package dbms_application_info_wa is
--
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : dbms_application_info_wa(spec)
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
procedure set_module(module_name varchar2, action_name varchar2);
procedure set_action(action_name varchar2);
procedure read_module(module_name out varchar2, action_name out varchar2);
procedure set_client_info(client_info varchar2);
procedure read_client_info(client_info out varchar2);
procedure set_session_longops(rindex      in out pls_integer,
                              slno        in out pls_integer,
                              op_name     in varchar2 default null,
                              target      in pls_integer default 0,
                              context     in pls_integer default 0,
                              sofar       in number default 0,
                              totalwork   in number default 0,
                              target_desc in varchar2
                                             default 'unknown target',
                              units       in varchar2 default null);
set_session_longops_nohint constant pls_integer := -1;
pragma TIMESTAMP('1998-03-12:12:00:00');
end;
/
