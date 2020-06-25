CREATE OR REPLACE PACKAGE BODY APPS.XX034DD002C
AS
/*****************************************************************************************
 * 
 * Copyright(c)Oracle Corporation Japan, 2005. All rights reserved.
 *
 * Package Name     : XX034DD002C(body)
 * Description      : �C���^�[�t�F�[�X�e�[�u������̎d��`�[�f�[�^�C���|�[�g
 * MD.050(CMD.040)  : ������̓o�b�`�����iGL�j       OCSJ/BFAFIN/MD050/F602
 * MD.070(CMD.050)  : ������́iGL�j�f�[�^�C���|�[�g OCSJ/BFAFIN/MD070/F602/03
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  print_header           �w�b�_���o��
 *  ins_header_data        �`�[�w�b�_���R�[�h�C���T�[�g
 *  ins_detail_data        �`�[���׃��R�[�h�C���T�[�g
 *  check_header_data      �`�[�w�b�_�f�[�^�̓��̓`�F�b�N
 *  check_detail_data      �`�[���׃f�[�^�̓��̓`�F�b�N
 *  check_head_line_new    �`�[�f�[�^�́i�w�b�_���׊֘A�ɂ��j���̓`�F�b�N
 *  copy_if_data           �C���^�[�t�F�[�X�f�[�^�̃R�s�[�i�R���g���[�����C���j
 *  update_slip_number     �������ԍ��Ǘ��e�[�u���̍X�V
 *  out_result             �I������
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2004/11/10   1.0            �V�K�쐬
 *  2005/06/09   11.5.10.1.3    ����Ȗڎ擾�G���[,�\�����̎擾�s��ɑΉ�
 *  2005/09/05   11.5.10.1.5    �p�t�H�[�}���X���P�Ή�
 *  2005/10/20   11.5.10.1.5B   ���F�҃r���[�Ƃ̌����s��Ή�
 *  2005/10/20   11.5.10.1.6    �ŋ��R�[�h�̗L���`�F�b�N�Ή�
 *                              �w�b�_���׏��J�[�\���ɂĐŋ敪�擾����
 *                              ���������t�ɂ����ėL���Ȑŋ敪���擾����悤�ɕύX
 *  2005/12/19   11.5.10.1.6B   ���F�҂̔��f��̏C���Ή�
 *  2005/12/28   11.5.10.1.6C   �`�[��ʂɃA�v���P�[�V�������̍i���݂�ǉ�
 *  2006/01/06   11.5.10.1.6D   �`�[�ԍ��̍̔ԏ����ɃI���O��ǉ�
 *  2006/03/01   11.5.10.1.6E   �e�^�C�~���O�ňقȂ�}�X�^�`�F�b�N�𓯂��ɂ���
 *  2006/05/08   11.5.10.2.2    �[���~���׎捞�Ή��A����ɔ����`�F�b�N���ڂ̕ύX
 *  2006/05/08   11.5.10.2.2B   �G���[���̃��b�Z�[�W���̏C��
 *  2006/09/05   11.5.10.2.5    �A�b�v���[�h�����ŕ������[�U�̓������s�\�Ƃ���
 *                              ����̌��A�f�[�^�폜�����̌��C��
 *                              ���b�Z�[�W�R�[�h�̌��C��
 *  2006/09/15   11.5.10.2.5B   ���ׂ̓��͂��Ă��Ȃ��ݎ؂̋��z��0���ݒ肳���C��
 *  2006/09/20   11.5.10.2.5C   �������s���\�Ƃ���Ή��̍ďC��
 *  2006/10/04   11.5.10.2.6    �}�X�^�`�F�b�N�̌�����(�L�����̃`�F�b�N�𐿋������t��
 *                              �s�Ȃ����ڂ�SYSDATE�ōs�Ȃ����ڂ��Ċm�F)
 *  2007/02/23   11.5.10.2.7    �v���O�������s���̃��[�U�E�E�ӂɕR�t�����j���[��
 *                              �o�^����Ă���`�[��ʂ��̃`�F�b�N��ǉ�
 *  2007/07/17   11.5.10.2.10   �}�X�^�`�F�b�N�̒ǉ�(���ׁF�ŋ敪�ݕ�/�ؕ�,�������R)
 *  2007/10/10   11.5.10.2.10B  �p�t�H�[�}���X�Ή��̂��ߏ��F�҂̃`�F�b�NSQL��
 *                              ���C��SQL�֑g�ݍ��ނ悤�ɏC��
 *  2007/10/29   11.5.10.2.10C  �ʉ݂̐��x�`�F�b�N(���͉\���x�����`�F�b�N)�ǉ��̂���
 *                              �`�[���擾���ɒʉݏ����Ɋۂ߂鏈�����폜
 *  2016/11/04   1.1            ��Q�Ή�E_�{�ғ�_13901
 *  2020/06/17   1.2            ��Q�Ή�E_�{�ғ�_16418
 *
 *****************************************************************************************/
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
--
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  cv_appli_cd         CONSTANT VARCHAR2(30)  := 'GL';                      --�A�v���P�[�V�������2
  cv_package_name     CONSTANT VARCHAR2(20)  := 'XX034DD002';              --�p�b�P�[�W��
  cv_yes              CONSTANT VARCHAR2(1)   := 'Y';  --�͂�
  cv_no               CONSTANT VARCHAR2(1)   := 'N';  --������
  cv_dept_normal      CONSTANT VARCHAR2(1)   := 'S';  -- �d��`�F�b�N���ʁi����j
  cv_dept_warning     CONSTANT VARCHAR2(1)   := 'W';  -- �d��`�F�b�N���ʁi�x���j
  cv_dept_error       CONSTANT VARCHAR2(1)   := 'E';  -- �d��`�F�b�N���ʁi�G���[�j
  cv_result_normal    CONSTANT VARCHAR2(1)   := '0';  -- �I���X�e�[�^�X�i����j
  cv_result_warning   CONSTANT VARCHAR2(1)   := '1';  -- �I���X�e�[�^�X�i�x���j
  cv_result_error     CONSTANT VARCHAR2(1)   := '2';  -- �I���X�e�[�^�X�i�G���[�j
--
  -- ver 11.5.10.2.7 Add Start
  cv_menu_url_inp   CONSTANT VARCHAR2(100) := 'OA.jsp?page=/oracle/apps/xx03/gl/input/webui/Xx03JournalInputPG';
  -- ver 11.5.10.2.7 Add End
--
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gn_journal_id NUMBER;       -- �`�[ID
  gn_error_count NUMBER;      -- �G���[����
  gv_result VARCHAR2(1);      -- �`�F�b�N���ʃX�e�[�^�X
--
-- Ver11.5.10.1.5 2005/09/06 Add Start
  gn_org_id      NUMBER;              -- �I���OID
  gv_cur_code    VARCHAR2(15);        -- �@�\�ʉ݃R�[�h
-- Ver11.5.10.1.5 2005/09/06 Add End
  -- ===============================
  -- �O���[�o���J�[�\��
  -- ===============================
--
-- Ver11.5.10.1.5 2005/09/06 Delete Start
--  -- �w�b�_���J�[�\��
--  CURSOR xx03_if_header_cur(h_source VARCHAR2,
--                            h_request_id NUMBER)
--  IS
--    SELECT 
--      xjsi.INTERFACE_ID as INTERFACE_ID,                        -- �C���^�[�t�F�[�XID
--      xjsi.WF_STATUS as WF_STATUS,                              -- �X�e�[�^�X
--      xstl.LOOKUP_CODE as SLIP_TYPE,                            -- �`�[���
--      TRUNC(xjsi.ENTRY_DATE, 'DD') as ENTRY_DATE,               -- �N�[��
--      xpp.PERSON_ID as REQUESTOR_PERSON_ID,                     -- �\����
--      xpp.EMPLOYEE_DISP as REQUESTOR_PERSON_NAME,               -- �\���Җ�
--      xapl.PERSON_ID as APPROVER_PERSON_ID,                     -- ���F��
--      xapl.EMPLOYEE_DISP as APPROVER_PERSON_NAME,               -- ���F�Җ�
--      xjsi.INVOICE_CURRENCY_CODE as INVOICE_CURRENCY_CODE,      -- �ʉ�
--      xjsi.EXCHANGE_RATE as EXCHANGE_RATE,                      -- ���[�g
--      xct.CONVERSION_TYPE as EXCHANGE_RATE_TYPE,                -- ���[�g�^�C�v
--      xjsi.EXCHANGE_RATE_TYPE_NAME as EXCHANGE_RATE_TYPE_NAME,  -- ���[�g�^�C�v��
--      xjsi.IGNORE_RATE_FLAG as IGNORE_RATE_FLAG,                -- ���Z�ϋ��z�����敪
--      xjsi.DESCRIPTION as DESCRIPTION,                          -- ���l
--      xpp.ATTRIBUTE28 as ENTRY_DEPARTMENT,                      -- �N�[����
--      xpp2.PERSON_ID as ENTRY_PERSON_ID,                        -- �`�[���͎�
--      xjsi.PERIOD_NAME as PERIOD_NAME,                          -- ��v����
--      xjsi.GL_DATE as GL_DATE,                                  -- �v���
--      xgto.CALCULATION_LEVEL_CODE as AUTO_TAX_CALC_FLAG,        -- ����Ōv�Z���x��
--      xgto.INPUT_ROUNDING_RULE_CODE as AP_TAX_ROUNDING_RULE,    -- ����Œ[������
--      xjsi.ORG_ID as ORG_ID,                                    -- �I���OID
--      xjsi.SET_OF_BOOKS_ID as SET_OF_BOOKS_ID,                  -- ��v����ID
--      xjsi.CREATED_BY as CREATED_BY, 
--      xjsi.CREATION_DATE as CREATION_DATE, 
--      xjsi.LAST_UPDATED_BY as LAST_UPDATED_BY, 
--      xjsi.LAST_UPDATE_DATE as LAST_UPDATE_DATE, 
--      xjsi.LAST_UPDATE_LOGIN as LAST_UPDATE_LOGIN, 
--      xjsi.REQUEST_ID as REQUEST_ID, 
--      xjsi.PROGRAM_APPLICATION_ID as PROGRAM_APPLICATION_ID, 
--      xjsi.PROGRAM_ID as PROGRAM_ID, 
--      xjsi.PROGRAM_UPDATE_DATE as PROGRAM_UPDATE_DATE
--     FROM 
--      XX03_JOURNAL_SLIPS_IF xjsi,
--      XX03_SLIP_TYPES_LOV_V xstl,
--      XX03_PER_PEOPLES_V xpp,
--      XX03_PER_PEOPLES_V xpp2,
--      XX03_APPROVER_PERSON_LOV_V xapl,
--      XX03_CONVERSION_TYPES_V xct,
--      XX03_GL_TAX_OPTIONS_V xgto
--     WHERE 
--      xjsi.REQUEST_ID = h_request_id
--      AND xjsi.SOURCE = h_source
--      AND xjsi.SLIP_TYPE_NAME = xstl.DESCRIPTION (+)
--      AND xjsi.REQUESTOR_PERSON_NUMBER = xpp.EMPLOYEE_NUMBER (+)
--      AND xjsi.ENTRY_PERSON_NUMBER = xpp2.EMPLOYEE_NUMBER (+)
--      AND xjsi.APPROVER_PERSON_NUMBER = xapl.EMPLOYEE_NUMBER (+)
--      AND xjsi.EXCHANGE_RATE_TYPE_NAME = xct.USER_CONVERSION_TYPE (+)
--      AND xjsi.ORG_ID = xgto.ORG_ID (+)
--      AND xjsi.SET_OF_BOOKS_ID = xgto.SET_OF_BOOKS_ID (+)
--     ORDER BY 
--      xjsi.INTERFACE_ID;
----
--  --  �w�b�_���J�[�\�����R�[�h�^
--  xx03_if_header_rec    xx03_if_header_cur%ROWTYPE;
----
--  -- ���׏��J�[�\��
--  CURSOR xx03_if_detail_cur(h_source VARCHAR2,
--                            h_request_id NUMBER,
--                            h_interface_id NUMBER,
--                            h_currency_code VARCHAR2,
--                            s_currency_code VARCHAR2)
--  IS
--    SELECT 
--      xjsli.INTERFACE_ID as INTERFACE_ID,                           -- �C���^�[�t�F�[�XID
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_DR,0,NULL,xjsli.ENTERED_ITEM_AMOUNT_DR),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--               ) as ENTERED_ITEM_AMOUNT_DR,                         -- �{�̋��z
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_DR,0,
--                  DECODE(xjsli.ENTERED_TAX_AMOUNT_DR,0,NULL,xjsli.ENTERED_TAX_AMOUNT_DR), xjsli.ENTERED_TAX_AMOUNT_DR),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--               ) as ENTERED_TAX_AMOUNT_DR,                          -- ����Ŋz
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_DR,0,
--                  DECODE(xjsli.ACCOUNTED_AMOUNT_DR,0,NULL,xjsli.ACCOUNTED_AMOUNT_DR), xjsli.ACCOUNTED_AMOUNT_DR),
--                  xx00_currency_pkg.get_format_mask(s_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(s_currency_code, 38)
--               ) as ACCOUNTED_AMOUNT_DR,                            -- ���Z�ϋ��z
--      xjsli.AMOUNT_INCLUDES_TAX_FLAG_DR as AMOUNT_INCLUDES_TAX_FLAG_DR,   -- ����
--      xjsli.TAX_CODE_DR as TAX_CODE_DR,                             -- �ŋ敪
--      xtcl.TAX_CODES_COL as TAX_NAME_DR,                            -- �ŋ敪��
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_CR,0,NULL,xjsli.ENTERED_ITEM_AMOUNT_CR),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--               ) as ENTERED_ITEM_AMOUNT_CR,                         -- �{�̋��z
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_CR,0,
--                  DECODE(xjsli.ENTERED_TAX_AMOUNT_CR,0,NULL,xjsli.ENTERED_TAX_AMOUNT_CR), xjsli.ENTERED_TAX_AMOUNT_CR),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--               ) as ENTERED_TAX_AMOUNT_CR,                          -- ����Ŋz
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_CR,0,
--                  DECODE(xjsli.ACCOUNTED_AMOUNT_CR,0,NULL,xjsli.ACCOUNTED_AMOUNT_CR), xjsli.ACCOUNTED_AMOUNT_CR),
--                  xx00_currency_pkg.get_format_mask(s_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(s_currency_code, 38)
--               ) as ACCOUNTED_AMOUNT_CR,                            -- ���Z�ϋ��z
--      xjsli.AMOUNT_INCLUDES_TAX_FLAG_CR as AMOUNT_INCLUDES_TAX_FLAG_CR,   -- ����
--      xjsli.TAX_CODE_CR as TAX_CODE_CR,                             -- �ŋ敪
--      xtcl2.TAX_CODES_COL as TAX_NAME_CR,                           -- �ŋ敪��
--      xjsli.DESCRIPTION as DESCRIPTION,                             -- ���l
--      xjsli.SEGMENT1 as SEGMENT1,                                   -- ���
--      xjsli.SEGMENT2 as SEGMENT2,                                   -- ����
--      xjsli.SEGMENT3 as SEGMENT3,                                   -- ����Ȗ�
--      xjsli.SEGMENT4 as SEGMENT4,                                   -- �⏕�Ȗ�
--      xjsli.SEGMENT5 as SEGMENT5,                                   -- �����
--      xjsli.SEGMENT6 as SEGMENT6,                                   -- ���Ƌ敪
--      xjsli.SEGMENT7 as SEGMENT7,                                   -- �v���W�F�N�g
--      xjsli.SEGMENT8 as SEGMENT8,                                   -- �\��
--      xcl.COMPANIES_COL as SEGMENT1_NAME,                           -- ��Ж�
--      xdl.DEPARTMENTS_COL as SEGMENT2_NAME,                         -- ���喼
--      xal.ACCOUNTS_COL as SEGMENT3_NAME,                            -- ����Ȗږ�
--      xsal.SUB_ACCOUNTS_COL as SEGMENT4_NAME,                       -- �⏕�Ȗږ�
--      xpal.PARTNERS_COL as SEGMENT5_NAME,                           -- ����於
--      xbtl.BUSINESS_TYPES_COL as SEGMENT6_NAME,                     -- ���Ƌ敪��
--      xprl.PROJECTS_COL as SEGMENT7_NAME,                           -- �v���W�F�N�g��
--    --Ver11.5.10.1.3 Modify START
--      --xjsli.SEGMENT8 as SEGMENT8_NAME,                             -- �\��
--      xfl.FUTURES_COL as SEGMENT8_NAME,                             -- �\��
--    --Ver11.5.10.1.3 Modify END
--      xjsli.INCR_DECR_REASON_CODE as INCR_DECR_REASON_CODE,         -- �������R
--      xidrl.INCR_DECR_REASONS_COL as INCR_DECR_REASON_NAME,         -- �������R��
--      xjsli.RECON_REFERENCE as RECON_REFERENCE,                     -- �����Q��
--      xjsli.ORG_ID as ORG_ID,                                       -- �I���OID
--      xjsli.CREATED_BY,
--      xjsli.CREATION_DATE,
--      xjsli.LAST_UPDATED_BY,
--      xjsli.LAST_UPDATE_DATE,
--      xjsli.LAST_UPDATE_LOGIN,
--      xjsli.REQUEST_ID,
--      xjsli.PROGRAM_APPLICATION_ID,
--      xjsli.PROGRAM_ID,
--      xjsli.PROGRAM_UPDATE_DATE
--    FROM 
--      XX03_JOURNAL_SLIP_LINES_IF xjsli,
--      XX03_TAX_CODES_LOV_V xtcl,
--      XX03_TAX_CODES_LOV_V xtcl2,
--      XX03_COMPANIES_LOV_V xcl,
--      XX03_DEPARTMENTS_LOV_V xdl,
--    --Ver11.5.10.1.3 Modify Start
--      --XX03_ACCOUNTS_LOV_V xal,
--      XX03_ACCOUNTS_ALL_LOV_V xal,
--      XX03_FUTURES_LOV_V xfl,
--    --Ver11.5.10.1.3 Modify End
--      XX03_SUB_ACCOUNTS_LOV_V xsal,
--      XX03_PARTNERS_LOV_V xpal,
--      XX03_BUSINESS_TYPES_LOV_V xbtl,
--      XX03_PROJECTS_LOV_V xprl,
--      XX03_INCR_DECR_REASONS_LOV_V xidrl
--    WHERE 
--      xjsli.REQUEST_ID = h_request_id
--      AND xjsli.SOURCE = h_source
--      AND xjsli.INTERFACE_ID = h_interface_id
--      AND xjsli.TAX_CODE_DR = xtcl.NAME (+)
--      AND xjsli.TAX_CODE_CR = xtcl2.NAME (+)
--      AND xjsli.SEGMENT1 = xcl.FLEX_VALUE (+)
--      AND xjsli.SEGMENT2 = xdl.FLEX_VALUE (+)
--      AND xjsli.SEGMENT3 = xal.FLEX_VALUE (+)
--      AND xjsli.SEGMENT4 = xsal.FLEX_VALUE (+)
--      AND xjsli.SEGMENT3 = xsal.PARENT_FLEX_VALUE_LOW (+)
--      AND xjsli.SEGMENT5 = xpal.FLEX_VALUE (+)
--      AND xjsli.SEGMENT6 = xbtl.FLEX_VALUE (+)
--      AND xjsli.SEGMENT7 = xprl.FLEX_VALUE (+)
--    --Ver11.5.10.1.3 add START
--      AND xjsli.SEGMENT8 = xfl.FLEX_VALUE (+)
--    --Ver11.5.10.1.3 add END
--      AND xjsli.INCR_DECR_REASON_CODE = xidrl.FLEX_VALUE (+)
--      AND xjsli.SEGMENT3 = xidrl.PARENT_FLEX_VALUE_LOW (+)
--    ORDER BY 
--      xjsli.LINE_NUMBER;
----
--  -- ���׏��J�[�\�����R�[�h�^
--  xx03_if_detail_rec xx03_if_detail_cur%ROWTYPE;
--
-- Ver11.5.10.1.5 2005/09/06 Delete End
--
-- Ver11.5.10.1.5 2005/09/06 Add Start
  -- �w�b�_���׏��J�[�\��
  CURSOR xx03_if_head_line_cur( h_source        VARCHAR2
                               ,h_request_id    NUMBER
                               ,h_base_cur_code VARCHAR2)
  IS
    SELECT
       HEAD.INTERFACE_ID           as HEAD_INTERFACE_ID                  -- �C���^�[�t�F�[�XID
     , HEAD.WF_STATUS              as HEAD_WF_STATUS                     -- �X�e�[�^�X
     , HEAD.SLIP_TYPE              as HEAD_SLIP_TYPE                     -- �`�[���
-- Ver11.5.10.1.6B Add Start
     , HEAD.SLIP_TYPE_APP          as HEAD_SLIP_TYPE_APP                 -- �`�[��ʃA�v���P�[�V����
-- Ver11.5.10.1.6B Add End
     , HEAD.ENTRY_DATE             as HEAD_ENTRY_DATE                    -- �N�[��
     , HEAD.REQUESTOR_PERSON_ID    as HEAD_REQUESTOR_PERSON_ID           -- �\����
     , HEAD.REQUESTOR_PERSON_NAME  as HEAD_REQUESTOR_PERSON_NAME         -- �\���Җ�
     , HEAD.APPROVER_PERSON_ID     as HEAD_APPROVER_PERSON_ID            -- ���F��
     , HEAD.APPROVER_PERSON_NAME   as HEAD_APPROVER_PERSON_NAME          -- ���F�Җ�
     , HEAD.INVOICE_CURRENCY_CODE  as HEAD_INVOICE_CURRENCY_CODE         -- �ʉ�
     , HEAD.EXCHANGE_RATE          as HEAD_EXCHANGE_RATE                 -- ���[�g
     , HEAD.EXCHANGE_RATE_TYPE     as HEAD_EXCHANGE_RATE_TYPE            -- ���[�g�^�C�v
     , HEAD.EXCHANGE_RATE_TYPE_NAME  as HEAD_EXCHANGE_RATE_TYPE_NAME     -- ���[�g�^�C�v��
     , HEAD.IGNORE_RATE_FLAG       as HEAD_IGNORE_RATE_FLAG              -- ���Z�ϋ��z�����敪
     , HEAD.DESCRIPTION            as HEAD_DESCRIPTION                   -- ���l
     , HEAD.ENTRY_DEPARTMENT       as HEAD_ENTRY_DEPARTMENT              -- �N�[����
     , HEAD.ENTRY_PERSON_ID        as HEAD_ENTRY_PERSON_ID               -- �`�[���͎�
     , HEAD.PERIOD_NAME            as HEAD_PERIOD_NAME                   -- ��v����
     , HEAD.GL_DATE                as HEAD_GL_DATE                       -- �v���
     , HEAD.AUTO_TAX_CALC_FLAG     as HEAD_AUTO_TAX_CALC_FLAG            -- ����Ōv�Z���x��
     , HEAD.AP_TAX_ROUNDING_RULE   as HEAD_AP_TAX_ROUNDING_RULE          -- ����Œ[������
     , HEAD.ORG_ID                 as HEAD_ORG_ID                        -- �I���OID
     , HEAD.SET_OF_BOOKS_ID        as HEAD_SET_OF_BOOKS_ID               -- ��v����ID
     , HEAD.CREATED_BY             as HEAD_CREATED_BY
     , HEAD.CREATION_DATE          as HEAD_CREATION_DATE
     , HEAD.LAST_UPDATED_BY        as HEAD_LAST_UPDATED_BY
     , HEAD.LAST_UPDATE_DATE       as HEAD_LAST_UPDATE_DATE
     , HEAD.LAST_UPDATE_LOGIN      as HEAD_LAST_UPDATE_LOGIN
     , HEAD.REQUEST_ID             as HEAD_REQUEST_ID
     , HEAD.PROGRAM_APPLICATION_ID as HEAD_PROGRAM_APPLICATION_ID
     , HEAD.PROGRAM_ID             as HEAD_PROGRAM_ID
     , HEAD.PROGRAM_UPDATE_DATE    as HEAD_PROGRAM_UPDATE_DATE
     , LINE.INTERFACE_ID           as LINE_INTERFACE_ID                  -- �C���^�[�t�F�[�XID
     , LINE.LINE_NUMBER            as LINE_LINE_NUMBER                   -- ���הԍ�
     -- ver 11.5.10.2.10C Chg Start
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_ITEM_AMOUNT_DR
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_ITEM_AMOUNT_DR        -- �{�̋��z
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_TAX_AMOUNT_DR
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_TAX_AMOUNT_DR         -- ����Ŋz
     --, TO_NUMBER( TO_CHAR( LINE.ACCOUNTED_AMOUNT_DR
     --                     ,xx00_currency_pkg.get_format_mask(h_base_cur_code, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(h_base_cur_code, 38)
     --            )                 as LINE_ACCOUNTED_AMOUNT_DR           -- ���Z�ϋ��z
     , LINE.ENTERED_ITEM_AMOUNT_DR as LINE_ENTERED_ITEM_AMOUNT_DR        -- �{�̋��z
     , LINE.ENTERED_TAX_AMOUNT_DR  as LINE_ENTERED_TAX_AMOUNT_DR         -- ����Ŋz
     , LINE.ACCOUNTED_AMOUNT_DR    as LINE_ACCOUNTED_AMOUNT_DR           -- ���Z�ϋ��z
     -- ver 11.5.10.2.10C Chg End
     , LINE.AMOUNT_INCLUDES_TAX_FLAG_DR  as LINE_AMOUNT_INC_TAX_FLAG_DR  -- ����
     , LINE.TAX_CODE_DR            as LINE_TAX_CODE_DR                   -- �ŋ敪
     , LINE.TAX_NAME_DR            as LINE_TAX_NAME_DR                   -- �ŋ敪��
     -- ver 11.5.10.2.10C Chg Start
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_ITEM_AMOUNT_CR
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_ITEM_AMOUNT_CR        -- �{�̋��z
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_TAX_AMOUNT_CR
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_TAX_AMOUNT_CR         -- ����Ŋz
     --, TO_NUMBER( TO_CHAR( LINE.ACCOUNTED_AMOUNT_CR
     --                     ,xx00_currency_pkg.get_format_mask(h_base_cur_code, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(h_base_cur_code, 38)
     --            )                 as LINE_ACCOUNTED_AMOUNT_CR           -- ���Z�ϋ��z
     , LINE.ENTERED_ITEM_AMOUNT_CR as LINE_ENTERED_ITEM_AMOUNT_CR        -- �{�̋��z
     , LINE.ENTERED_TAX_AMOUNT_CR  as LINE_ENTERED_TAX_AMOUNT_CR         -- ����Ŋz
     , LINE.ACCOUNTED_AMOUNT_CR    as LINE_ACCOUNTED_AMOUNT_CR           -- ���Z�ϋ��z
     -- ver 11.5.10.2.10C Chg End
     , LINE.AMOUNT_INCLUDES_TAX_FLAG_CR  as LINE_AMOUNT_INC_TAX_FLAG_CR  -- ����
     , LINE.TAX_CODE_CR            as LINE_TAX_CODE_CR                   -- �ŋ敪
     , LINE.TAX_NAME_CR            as LINE_TAX_NAME_CR                   -- �ŋ敪��
     , LINE.DESCRIPTION            as LINE_DESCRIPTION                   -- ���l
     , LINE.SEGMENT1               as LINE_SEGMENT1                      -- ���
     , LINE.SEGMENT1_NAME          as LINE_SEGMENT1_NAME                 -- ��Ж�
     , LINE.SEGMENT2               as LINE_SEGMENT2                      -- ����
     , LINE.SEGMENT2_NAME          as LINE_SEGMENT2_NAME                 -- ���喼
     , LINE.SEGMENT3               as LINE_SEGMENT3                      -- ����Ȗ�
     , LINE.SEGMENT3_NAME          as LINE_SEGMENT3_NAME                 -- ����Ȗږ�
     , LINE.SEGMENT4               as LINE_SEGMENT4                      -- �⏕�Ȗ�
     , LINE.SEGMENT4_NAME          as LINE_SEGMENT4_NAME                 -- �⏕�Ȗږ�
     , LINE.SEGMENT5               as LINE_SEGMENT5                      -- �����
     , LINE.SEGMENT5_NAME          as LINE_SEGMENT5_NAME                 -- ����於
     , LINE.SEGMENT6               as LINE_SEGMENT6                      -- ���Ƌ敪
     , LINE.SEGMENT6_NAME          as LINE_SEGMENT6_NAME                 -- ���Ƌ敪��
     , LINE.SEGMENT7               as LINE_SEGMENT7                      -- �v���W�F�N�g
     , LINE.SEGMENT7_NAME          as LINE_SEGMENT7_NAME                 -- �v���W�F�N�g��
     , LINE.SEGMENT8               as LINE_SEGMENT8                      -- �\��
     , LINE.SEGMENT8_NAME          as LINE_SEGMENT8_NAME                 -- �\����
     , LINE.INCR_DECR_REASON_CODE  as LINE_INCR_DECR_REASON_CODE         -- �������R
     , LINE.INCR_DECR_REASON_NAME  as LINE_INCR_DECR_REASON_NAME         -- �������R��
     , LINE.RECON_REFERENCE        as LINE_RECON_REFERENCE               -- �����Q��
     , LINE.ORG_ID                 as LINE_ORG_ID                        -- �I���OID
-- == 2016/11/04 V1.1 Added START ===============================================================
     , LINE.ATTRIBUTE9             as LINE_ATTRIBUTE9                    -- �g�c���ٔԍ�
-- == 2016/11/04 V1.1 Added END =================================================================
     , LINE.CREATED_BY             as LINE_CREATED_BY
     , LINE.CREATION_DATE          as LINE_CREATION_DATE
     , LINE.LAST_UPDATED_BY        as LINE_LAST_UPDATED_BY
     , LINE.LAST_UPDATE_DATE       as LINE_LAST_UPDATE_DATE
     , LINE.LAST_UPDATE_LOGIN      as LINE_LAST_UPDATE_LOGIN
     , LINE.REQUEST_ID             as LINE_REQUEST_ID
     , LINE.PROGRAM_APPLICATION_ID as LINE_PROGRAM_APPLICATION_ID
     , LINE.PROGRAM_ID             as LINE_PROGRAM_ID
     , LINE.PROGRAM_UPDATE_DATE    as LINE_PROGRAM_UPDATE_DATE
     , CNT.INTERFACE_ID            as CNT_INTERFACE_ID                   -- �C���^�[�t�F�[�XID
     , CNT.REC_COUNT               as CNT_REC_COUNT                      --
     -- ver 11.5.10.2.10B Add Start
     , APPROVER.PERSON_ID          as APPROVER_PERSON_ID
     -- ver 11.5.10.2.10B Add End
    FROM
       (SELECT
           xjsi.INTERFACE_ID         as INTERFACE_ID                  -- �C���^�[�t�F�[�XID
         , xjsi.WF_STATUS            as WF_STATUS                     -- �X�e�[�^�X
         , xstl.LOOKUP_CODE          as SLIP_TYPE                     -- �`�[���
-- Ver11.5.10.1.6B Add Start
         , xstl.ATTRIBUTE14          as SLIP_TYPE_APP                 -- �`�[��ʃA�v���P�[�V����
-- Ver11.5.10.1.6B Add End
         , TRUNC(xjsi.ENTRY_DATE, 'DD')  as ENTRY_DATE                -- �N�[��
         , xpp.PERSON_ID             as REQUESTOR_PERSON_ID           -- �\����
         , xpp.EMPLOYEE_DISP         as REQUESTOR_PERSON_NAME         -- �\���Җ�
-- Ver11.5.10.1.5B Chg Start
         --, xapl.PERSON_ID            as APPROVER_PERSON_ID            -- ���F��
         --, xapl.EMPLOYEE_DISP        as APPROVER_PERSON_NAME          -- ���F�Җ�
         , ppf.person_id               as APPROVER_PERSON_ID          -- ���F��
         , ppf.EMPLOYEE_NUMBER || 
           XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || 
           ppf.PER_INFORMATION18 || ' ' || 
           ppf.PER_INFORMATION19       as APPROVER_PERSON_NAME        -- ���F�Җ�
-- Ver11.5.10.1.5B Chg End
         , xjsi.INVOICE_CURRENCY_CODE  as INVOICE_CURRENCY_CODE       -- �ʉ�
         , xjsi.EXCHANGE_RATE        as EXCHANGE_RATE                 -- ���[�g
         , xct.CONVERSION_TYPE       as EXCHANGE_RATE_TYPE            -- ���[�g�^�C�v
         , xjsi.EXCHANGE_RATE_TYPE_NAME  as EXCHANGE_RATE_TYPE_NAME   -- ���[�g�^�C�v��
         , xjsi.IGNORE_RATE_FLAG     as IGNORE_RATE_FLAG              -- ���Z�ϋ��z�����敪
         , xjsi.DESCRIPTION          as DESCRIPTION                   -- ���l
         , xpp.ATTRIBUTE28           as ENTRY_DEPARTMENT              -- �N�[����
         , xpp2.PERSON_ID            as ENTRY_PERSON_ID               -- �`�[���͎�
         , xjsi.PERIOD_NAME          as PERIOD_NAME                   -- ��v����
         , xjsi.GL_DATE              as GL_DATE                       -- �v���
         , xgto.CALCULATION_LEVEL_CODE  as AUTO_TAX_CALC_FLAG         -- ����Ōv�Z���x��
         , xgto.INPUT_ROUNDING_RULE_CODE  as AP_TAX_ROUNDING_RULE     -- ����Œ[������
         , xjsi.ORG_ID               as ORG_ID                        -- �I���OID
         , xjsi.SET_OF_BOOKS_ID      as SET_OF_BOOKS_ID               -- ��v����ID
         , xjsi.CREATED_BY           as CREATED_BY
         , xjsi.CREATION_DATE        as CREATION_DATE
         , xjsi.LAST_UPDATED_BY      as LAST_UPDATED_BY
         , xjsi.LAST_UPDATE_DATE     as LAST_UPDATE_DATE
         , xjsi.LAST_UPDATE_LOGIN    as LAST_UPDATE_LOGIN
         , xjsi.REQUEST_ID           as REQUEST_ID
         , xjsi.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
         , xjsi.PROGRAM_ID           as PROGRAM_ID
         , xjsi.PROGRAM_UPDATE_DATE  as PROGRAM_UPDATE_DATE
        FROM
           XX03_JOURNAL_SLIPS_IF      xjsi
-- ver 11.5.10.2.7 Chg Start
-- -- Ver11.5.10.1.6C Chg Start
-- -- -- Ver11.5.10.1.6B Chg Start
-- -- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION
-- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION,XLXV.ATTRIBUTE14
-- -- -- Ver11.5.10.1.6B Chg End
-- --           FROM  XX03_SLIP_TYPES_V XLXV
-- --           WHERE XLXV.ENABLED_FLAG = 'Y' AND XLXV.ATTRIBUTE14 = 'SQLGL'
-- --           )                          xstl
--          ,(SELECT XSTLV.LOOKUP_CODE,XSTLV.DESCRIPTION,XSTLV.ATTRIBUTE14
--            FROM XX03_SLIP_TYPES_LOV_V XSTLV
--            WHERE XSTLV.ATTRIBUTE14 = 'SQLGL'
--            )                          xstl
         ,(select XSTLV.LOOKUP_CODE , XSTLV.DESCRIPTION , XSTLV.ATTRIBUTE14
             from XX03_SLIP_TYPES_LOV_V XSTLV , FND_FORM_FUNCTIONS FFF
            where XSTLV.ATTRIBUTE14 = 'SQLGL'
              and (   upper(FFF.PARAMETERS) like '%&SLIPTYPE=' || XSTLV.LOOKUP_CODE
                   or upper(FFF.PARAMETERS) like '%&SLIPTYPE=' || XSTLV.LOOKUP_CODE || '&%'
                   or upper(FFF.PARAMETERS) like 'SLIPTYPE='   || XSTLV.LOOKUP_CODE || '&%' )
              and WEB_HTML_CALL = cv_menu_url_inp
              and exists(select '1'
                           from ( (select X.FUNCTION_ID
                                     from ( select MENU_ID MENU_ID , SUB_MENU_ID SUB_MENU_ID , FUNCTION_ID FUNCTION_ID from FND_MENU_ENTRIES where GRANT_FLAG = 'Y'
                                             start with MENU_ID = (select MENU_ID from FND_RESPONSIBILITY where RESPONSIBILITY_ID  = xx00_global_pkg.resp_id) connect by prior SUB_MENU_ID = MENU_ID) X
                                    where X.FUNCTION_ID is not null)
                                  minus
                                  (select B.ACTION_ID FUNCTION_ID
                                     from FND_RESPONSIBILITY A , FND_RESP_FUNCTIONS B
                                    where A.RESPONSIBILITY_ID  = xx00_global_pkg.resp_id and A.APPLICATION_ID = xx00_global_pkg.resp_appl_id
                                      and B.APPLICATION_ID = A.APPLICATION_ID and B.RESPONSIBILITY_ID = A.RESPONSIBILITY_ID and B.RULE_TYPE = 'F')
                                  minus
                                  (select X.FUNCTION_ID
                                     from ( select AA.MENU_ID , AA.SUB_MENU_ID , AA.FUNCTION_ID
                                              from ( ( select MENU_ID MENU_ID , SUB_MENU_ID SUB_MENU_ID , FUNCTION_ID FUNCTION_ID from FND_MENU_ENTRIES where GRANT_FLAG = 'Y')
                                                     union all
                                                     (select 0 MENU_ID , B.ACTION_ID SUB_MENU_ID , null FUNCTION_ID from FND_RESPONSIBILITY A , FND_RESP_FUNCTIONS B
                                                       where A.RESPONSIBILITY_ID = xx00_global_pkg.resp_id and A.APPLICATION_ID = xx00_global_pkg.resp_appl_id
                                                         and B.APPLICATION_ID = A.APPLICATION_ID and B.RESPONSIBILITY_ID = A.RESPONSIBILITY_ID and B.RULE_TYPE = 'M')
                                                    ) AA
                                             start with AA.MENU_ID = 0 connect by prior AA.SUB_MENU_ID = AA.MENU_ID) X )
                                   ) Y
                           where Y.FUNCTION_ID = FFF.FUNCTION_ID)
           )                           xstl
-- ver 11.5.10.2.7 Chg End
-- Ver11.5.10.1.6C Chg End
         , XX03_PER_PEOPLES_V         xpp
         , XX03_PER_PEOPLES_V         xpp2
-- Ver11.5.10.1.5B Chg Start
         --, XX03_APPROVER_PERSON_LOV_V xapl
         , PER_PEOPLE_F               ppf
-- Ver11.5.10.1.5B Chg End
         , XX03_CONVERSION_TYPES_V    xct
         , GL_TAX_OPTIONS             xgto
        WHERE
              xjsi.REQUEST_ID               = h_request_id
          AND xjsi.SOURCE                   = h_source
          AND xjsi.SLIP_TYPE_NAME           = xstl.DESCRIPTION         (+)
          AND xjsi.REQUESTOR_PERSON_NUMBER  = xpp.EMPLOYEE_NUMBER      (+)
          AND xjsi.ENTRY_PERSON_NUMBER      = xpp2.EMPLOYEE_NUMBER     (+)
-- Ver11.5.10.1.5B Chg Start
          --AND xjsi.APPROVER_PERSON_NUMBER   = xapl.EMPLOYEE_NUMBER     (+)
          AND xjsi.APPROVER_PERSON_NUMBER   = ppf.EMPLOYEE_NUMBER      (+)
          AND TRUNC(SYSDATE) BETWEEN ppf.effective_start_date(+) AND ppf.effective_end_date(+)
          AND ppf.current_employee_flag(+) = 'Y'
-- Ver11.5.10.1.5B Chg End
          AND xjsi.EXCHANGE_RATE_TYPE_NAME  = xct.USER_CONVERSION_TYPE (+)
          AND xjsi.ORG_ID                   = xgto.ORG_ID              (+)
          AND xjsi.SET_OF_BOOKS_ID          = xgto.SET_OF_BOOKS_ID     (+)
        ) HEAD
      ,(SELECT
           xjsli.INTERFACE_ID        as INTERFACE_ID                  -- �C���^�[�t�F�[�XID
         , xjsli.LINE_NUMBER         as LINE_NUMBER                   -- ���הԍ�
         -- ver 11.5.10.2.2 Chg Start
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_DR
         --         ,0 ,NULL
         --         ,xjsli.ENTERED_ITEM_AMOUNT_DR)  as ENTERED_ITEM_AMOUNT_DR        -- �{�̋��z
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_DR
         --         ,0 ,DECODE( xjsli.ENTERED_TAX_AMOUNT_DR
         --                    ,0 ,NULL
         --                    ,xjsli.ENTERED_TAX_AMOUNT_DR)
         --         ,xjsli.ENTERED_TAX_AMOUNT_DR)   as ENTERED_TAX_AMOUNT_DR         -- ����Ŋz
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_DR
         --         ,0 ,DECODE( xjsli.ACCOUNTED_AMOUNT_DR
         --                    ,0 ,NULL
         --                    ,xjsli.ACCOUNTED_AMOUNT_DR)
         --         ,xjsli.ACCOUNTED_AMOUNT_DR)     as ACCOUNTED_AMOUNT_DR           -- ���Z�ϋ��z
         , xjsli.ENTERED_ITEM_AMOUNT_DR           as ENTERED_ITEM_AMOUNT_DR        -- �{�̋��z
         , xjsli.ENTERED_TAX_AMOUNT_DR            as ENTERED_TAX_AMOUNT_DR         -- ����Ŋz
         , xjsli.ACCOUNTED_AMOUNT_DR              as ACCOUNTED_AMOUNT_DR           -- ���Z�ϋ��z
         -- ver 11.5.10.2.2 Chg End
         , xjsli.AMOUNT_INCLUDES_TAX_FLAG_DR      as AMOUNT_INCLUDES_TAX_FLAG_DR   -- ����
         , xjsli.TAX_CODE_DR         as TAX_CODE_DR                   -- �ŋ敪
         , xtcl.TAX_CODES_COL        as TAX_NAME_DR                   -- �ŋ敪��
         -- ver 11.5.10.2.2 Chg Start
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_CR
         --         ,0 ,NULL
         --         ,xjsli.ENTERED_ITEM_AMOUNT_CR)  as ENTERED_ITEM_AMOUNT_CR        -- �{�̋��z
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_CR
         --         ,0 ,DECODE( xjsli.ENTERED_TAX_AMOUNT_CR
         --                    ,0 ,NULL
         --                    ,xjsli.ENTERED_TAX_AMOUNT_CR)
         --         ,xjsli.ENTERED_TAX_AMOUNT_CR)   as ENTERED_TAX_AMOUNT_CR         -- ����Ŋz
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_CR
         --         ,0 ,DECODE( xjsli.ACCOUNTED_AMOUNT_CR
         --                    ,0 ,NULL
         --                    ,xjsli.ACCOUNTED_AMOUNT_CR)
         --         ,xjsli.ACCOUNTED_AMOUNT_CR)     as ACCOUNTED_AMOUNT_CR           -- ���Z�ϋ��z
         , xjsli.ENTERED_ITEM_AMOUNT_CR           as ENTERED_ITEM_AMOUNT_CR        -- �{�̋��z
         , xjsli.ENTERED_TAX_AMOUNT_CR            as ENTERED_TAX_AMOUNT_CR         -- ����Ŋz
         , xjsli.ACCOUNTED_AMOUNT_CR              as ACCOUNTED_AMOUNT_CR           -- ���Z�ϋ��z
         -- ver 11.5.10.2.2 Chg End
         , xjsli.AMOUNT_INCLUDES_TAX_FLAG_CR      as AMOUNT_INCLUDES_TAX_FLAG_CR   -- ����
         , xjsli.TAX_CODE_CR         as TAX_CODE_CR                   -- �ŋ敪
         , xtcl2.TAX_CODES_COL       as TAX_NAME_CR                   -- �ŋ敪��
         , xjsli.DESCRIPTION         as DESCRIPTION                   -- ���l
         , xcl.FLEX_VALUE            as SEGMENT1                      -- ���
         , xcl.COMPANIES_COL         as SEGMENT1_NAME                 -- ��Ж�
         , xdl.FLEX_VALUE            as SEGMENT2                      -- ����
         , xdl.DEPARTMENTS_COL       as SEGMENT2_NAME                 -- ���喼
         , xal.FLEX_VALUE            as SEGMENT3                      -- ����Ȗ�
         , xal.ACCOUNTS_COL          as SEGMENT3_NAME                 -- ����Ȗږ�
         , xsal.FLEX_VALUE           as SEGMENT4                      -- �⏕�Ȗ�
         , xsal.SUB_ACCOUNTS_COL     as SEGMENT4_NAME                 -- �⏕�Ȗږ�
         , xpal.FLEX_VALUE           as SEGMENT5                      -- �����
         , xpal.PARTNERS_COL         as SEGMENT5_NAME                 -- ����於
         , xbtl.FLEX_VALUE           as SEGMENT6                      -- ���Ƌ敪
         , xbtl.BUSINESS_TYPES_COL   as SEGMENT6_NAME                 -- ���Ƌ敪��
         , xprl.FLEX_VALUE           as SEGMENT7                      -- �v���W�F�N�g
         , xprl.PROJECTS_COL         as SEGMENT7_NAME                 -- �v���W�F�N�g��
         , xfl.FLEX_VALUE            as SEGMENT8                      -- �\��
         , xfl.FUTURES_COL           as SEGMENT8_NAME                 -- �\����
         , xjsli.INCR_DECR_REASON_CODE  as INCR_DECR_REASON_CODE      -- �������R
         , xidrl.INCR_DECR_REASONS_COL  as INCR_DECR_REASON_NAME      -- �������R��
         , xjsli.RECON_REFERENCE     as RECON_REFERENCE               -- �����Q��
         , xjsli.ORG_ID              as ORG_ID                        -- �I���OID
-- == 2016/11/04 V1.1 Added START ===============================================================
         , xjsli.ATTRIBUTE9          as ATTRIBUTE9                    -- �g�c���ٔԍ�
-- == 2016/11/04 V1.1 Added END   ===============================================================
         , xjsli.CREATED_BY          as CREATED_BY
         , xjsli.CREATION_DATE       as CREATION_DATE
         , xjsli.LAST_UPDATED_BY     as LAST_UPDATED_BY
         , xjsli.LAST_UPDATE_DATE    as LAST_UPDATE_DATE
         , xjsli.LAST_UPDATE_LOGIN   as LAST_UPDATE_LOGIN
         , xjsli.REQUEST_ID          as REQUEST_ID
         , xjsli.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
         , xjsli.PROGRAM_ID          as PROGRAM_ID
         , xjsli.PROGRAM_UPDATE_DATE as PROGRAM_UPDATE_DATE
        FROM
         -- Ver11.5.10.1.6 2005/12/15 Change Start
         -- XX03_JOURNAL_SLIP_LINES_IF   xjsli
         --,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL
         --  FROM AP_TAX_CODES_ALL ATL
         --  WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
         --  )                            xtcl
         --,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL
         --  FROM AP_TAX_CODES_ALL ATL
         --  WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
         --  )                            xtcl2
         -- ver 11.5.10.2.6 Del Start
         --  XX03_JOURNAL_SLIPS_IF        xjsi
         -- ver 11.5.10.2.6 Del End
           XX03_JOURNAL_SLIP_LINES_IF   xjsli
         -- ver 11.5.10.2.6 Chg Start
         --,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL,
         --         ATL.START_DATE, ATL.INACTIVE_DATE
         --  FROM AP_TAX_CODES_ALL ATL
         --  WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
         --  )                            xtcl
         ,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL
                 ,xjsli.INTERFACE_ID ,xjsli.LINE_NUMBER
           FROM AP_TAX_CODES_ALL ATL ,XX03_JOURNAL_SLIPS_IF xjsi ,XX03_JOURNAL_SLIP_LINES_IF xjsli
           WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
             AND xjsli.TAX_CODE_DR = ATL.NAME AND xjsi.INTERFACE_ID = xjsli.INTERFACE_ID
             AND xjsi.GL_DATE BETWEEN NVL(ATL.START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(ATL.INACTIVE_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
             AND xjsi.REQUEST_ID = h_request_id AND xjsi.SOURCE = h_source AND xjsli.REQUEST_ID = h_request_id AND xjsli.SOURCE = h_source
           )                            xtcl
         -- ver 11.5.10.2.6 Chg End
         -- ver 11.5.10.2.6 Chg Start
         --,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL,
         --         ATL.START_DATE, INACTIVE_DATE
         --  FROM AP_TAX_CODES_ALL ATL
         --  WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
         --  )                            xtcl2
         ,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL
                 ,xjsli.INTERFACE_ID ,xjsli.LINE_NUMBER
           FROM AP_TAX_CODES_ALL ATL ,XX03_JOURNAL_SLIPS_IF xjsi ,XX03_JOURNAL_SLIP_LINES_IF xjsli
           WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
             AND xjsli.TAX_CODE_CR = ATL.NAME AND xjsi.INTERFACE_ID = xjsli.INTERFACE_ID
             AND xjsi.GL_DATE BETWEEN NVL(ATL.START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(ATL.INACTIVE_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
             AND xjsi.REQUEST_ID = h_request_id AND xjsi.SOURCE = h_source AND xjsli.REQUEST_ID = h_request_id AND xjsli.SOURCE = h_source
           )                            xtcl2
         -- ver 11.5.10.2.6 Chg End
         -- Ver11.5.10.1.6 2005/12/15 Change End
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION COMPANIES_COL
           FROM XX03_COMPANIES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xcl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION DEPARTMENTS_COL
           FROM XX03_DEPARTMENTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xdl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION ACCOUNTS_COL
           FROM XX03_ACCOUNTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xal
         ,(SELECT XV.PARENT_FLEX_VALUE_LOW,XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION SUB_ACCOUNTS_COL
           FROM XX03_SUB_ACCOUNTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xsal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION PARTNERS_COL
           FROM XX03_PARTNERS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xpal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION BUSINESS_TYPES_COL
           FROM XX03_BUSINESS_TYPES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xbtl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION PROJECTS_COL
           FROM XX03_PROJECTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xprl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION FUTURES_COL
           FROM XX03_FUTURES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xfl
         ,(SELECT XV.FFL_FLEX_VALUE FLEX_VALUE,XV.FFL_FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION INCR_DECR_REASONS_COL,XCC.ACCOUNT_CODE PARENT_FLEX_VALUE_LOW
           FROM XX03_INCR_DECR_REASONS_V XV
               ,XX03_CF_COMBINATIONS XCC
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND XCC.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') AND XCC.INCR_DECR_REASON_CODE = XV.FFL_FLEX_VALUE
           )                            xidrl
        WHERE
              xjsli.REQUEST_ID              = h_request_id
          AND xjsli.SOURCE                  = h_source
          -- ver 11.5.10.2.6 Chg Start
          ---- Ver11.5.10.1.6 2005/12/15 Add Start
          ---- ver 11.5.10.2.5C Add Start
          --AND xjsi.REQUEST_ID               = h_request_id
          --AND xjsi.SOURCE                   = h_source
          ---- ver 11.5.10.2.5C Add End
          --AND xjsi.INTERFACE_ID             = xjsli.INTERFACE_ID
          --AND xjsi.GL_DATE BETWEEN NVL(xtcl.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD')) 
          --                     AND NVL(xtcl.INACTIVE_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD'))
          --AND xjsi.GL_DATE BETWEEN NVL(xtcl2.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD')) 
          --                     AND NVL(xtcl2.INACTIVE_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD'))
          ---- Ver11.5.10.1.6 2005/12/15 Chg End
          AND xjsli.INTERFACE_ID            = xtcl.INTERFACE_ID           (+)
          AND xjsli.LINE_NUMBER             = xtcl.LINE_NUMBER            (+)
          AND xjsli.INTERFACE_ID            = xtcl2.INTERFACE_ID          (+)
          AND xjsli.LINE_NUMBER             = xtcl2.LINE_NUMBER           (+)
          -- ver 11.5.10.2.6 Chg End
          AND xjsli.TAX_CODE_DR             = xtcl.NAME                   (+)
          AND xjsli.TAX_CODE_CR             = xtcl2.NAME                  (+)
          AND xjsli.SEGMENT1                = xcl.FLEX_VALUE              (+)
          AND xjsli.SEGMENT2                = xdl.FLEX_VALUE              (+)
          AND xjsli.SEGMENT3                = xal.FLEX_VALUE              (+)
          AND xjsli.SEGMENT3                = xsal.PARENT_FLEX_VALUE_LOW  (+)
          AND xjsli.SEGMENT4                = xsal.FLEX_VALUE             (+)
          AND xjsli.SEGMENT5                = xpal.FLEX_VALUE             (+)
          AND xjsli.SEGMENT6                = xbtl.FLEX_VALUE             (+)
          AND xjsli.SEGMENT7                = xprl.FLEX_VALUE             (+)
          AND xjsli.SEGMENT8                = xfl.FLEX_VALUE              (+)
          AND xjsli.SEGMENT3                = xidrl.PARENT_FLEX_VALUE_LOW (+)
          AND xjsli.INCR_DECR_REASON_CODE   = xidrl.FLEX_VALUE            (+)
        ) LINE
     , (SELECT INTERFACE_ID         as INTERFACE_ID
              ,COUNT(INTERFACE_ID)  as REC_COUNT
        FROM   XX03_JOURNAL_SLIPS_IF
        WHERE  REQUEST_ID = h_request_id
          AND  SOURCE     = h_source
        GROUP BY INTERFACE_ID
        ) CNT
      -- ver 11.5.10.2.10B Add Start
      ,(SELECT xjsi.INTERFACE_ID as INTERFACE_ID
              ,ppf.PERSON_ID     as PERSON_ID
        FROM   XX03_JOURNAL_SLIPS_IF    xjsi
             ,(SELECT employee_number ,person_id FROM PER_PEOPLE_F
               WHERE current_employee_flag = 'Y' AND TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date
               ) ppf
        WHERE  xjsi.APPROVER_PERSON_NUMBER = ppf.EMPLOYEE_NUMBER
-- == V1.2 Added START ===============================================================
          AND  xjsi.request_id             = h_request_id
          AND  xjsi.source                 = h_source
-- == V1.2 Added END   ===============================================================
          AND  EXISTS (SELECT '1'
                       FROM   XX03_APPROVER_PERSON_LOV_V xaplv
                       WHERE  xaplv.PERSON_ID = ppf.person_id
                         AND (   xaplv.PROFILE_VAL_DEP = 'ALL'
                              or xaplv.PROFILE_VAL_DEP = 'SQLGL')
                       )
        ) APPROVER
      -- ver 11.5.10.2.10B Add End
    WHERE
          HEAD.INTERFACE_ID = LINE.INTERFACE_ID
      AND HEAD.INTERFACE_ID = CNT.INTERFACE_ID
      -- ver 11.5.10.2.10B Add Start
      AND HEAD.INTERFACE_ID = APPROVER.INTERFACE_ID(+)
      -- ver 11.5.10.2.10B Add End
    ORDER BY
       HEAD.INTERFACE_ID ,LINE.LINE_NUMBER
    ;
--
    -- �w�b�_���׏��J�[�\�����R�[�h�^
    xx03_if_head_line_rec  xx03_if_head_line_cur%ROWTYPE;
-- Ver11.5.10.1.5 2005/09/06 Add End
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : print_header
   * Description      : �w�b�_���o��
   ***********************************************************************************/
  PROCEDURE print_header(
    iv_source     IN  VARCHAR2,     -- 1.�\�[�X
    in_request_id IN  NUMBER,       -- 2.�v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'print_header'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_conc_name fnd_concurrent_programs.concurrent_program_name%TYPE;  -- �p�����[�^�o�͗p
    l_conc_para_rec        xx03_get_prompt_pkg.g_conc_para_tbl_type;    -- �p�����[�^�o�͗p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���O�o��
    xx00_file_pkg.log('iv_source = ' || iv_source);
    xx00_file_pkg.log('in_request_id = ' || TO_CHAR(in_request_id));
    xx00_file_pkg.log(' ');
--
    --�R���J�����g�o�͂̃w�b�_�[�����o��
    xx03_header_line_output_pkg.header_line_output_p(
                        cv_appli_cd,                                 -- �A�v���P�[�V�������
                        xx00_global_pkg.prog_appl_id,                -- �A�v���P�[�V����ID
                        xx00_profile_pkg.value('GL_SET_OF_BKS_ID'),  -- ��v����ID
                        NULL,                                        -- �I���OID
                        xx00_global_pkg.conc_program_id,             -- �R���J�����g�v���O����ID
                        ov_errbuf,
                        ov_retcode,
                        ov_errmsg
                       );
--
    -- ���s�o��
    xx00_file_pkg.output(' ');
--
    -- �R���J�����g�o�͂̃p�����[�^�����o��
    lv_conc_name := NULL;
    xx03_get_prompt_pkg.conc_parameter_strc(lv_conc_name,l_conc_para_rec);
    xx00_file_pkg.output(RPAD(l_conc_para_rec(1).PARAM_PROMPT,20)
                         ||':'|| iv_source);
    xx00_file_pkg.output(RPAD(l_conc_para_rec(2).PARAM_PROMPT,20)
                         ||':'|| TO_CHAR(in_request_id));
--
    -- ���s�o��
    xx00_file_pkg.output(' ');
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END print_header;
--
-- Ver11.5.10.1.5 2005/09/06 Change Start
--  /**********************************************************************************
--   * Procedure Name   : check_detail_data
--   * Description      : �d��`�[���׃f�[�^�̓��̓`�F�b�N(E-2)
--   ***********************************************************************************/
--  PROCEDURE check_detail_data(
--    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
--    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
--    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_detail_data'; -- �v���O������
----
----#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  �Œ蕔 END   ############################
----
--    -- ��Ѓ`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT1 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT1) = '' ) THEN
--      -- ��ЃZ�O�����g����̏ꍇ�͉�Г��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14114'
--        )
--      );
--    END IF;
----
--    -- ����`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT2 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT2) = '' ) THEN
--      -- ����Z�O�����g����̏ꍇ�͕�����̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14115'
--        )
--      );
--    END IF;
----
--    -- ����Ȗڃ`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT3 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT3) = '' ) THEN
--      -- ����ȖڃZ�O�����g����̏ꍇ�͊���Ȗړ��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14116'
--        )
--      );
--    END IF;
----
--    -- �⏕�Ȗڃ`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT4 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT4) = '' ) THEN
--      -- �⏕�ȖڃZ�O�����g����̏ꍇ�͕⏕�Ȗړ��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14117'
--        )
--      );
--    END IF;
----
--    -- �����`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT5 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT5) = '' ) THEN
--      -- �����Z�O�����g����̏ꍇ�͑������̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14118'
--        )
--      );
--    END IF;
----
--    -- ���Ƌ敪�`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT6 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT6) = '' ) THEN
--      -- ���Ƌ敪�Z�O�����g����̏ꍇ�͎��Ƌ敪���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14119'
--        )
--      );
--    END IF;
----
--    -- �v���W�F�N�g�`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT7 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT7) = '' ) THEN
--      -- �v���W�F�N�g�Z�O�����g����̏ꍇ�̓v���W�F�N�g���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14120'
--        )
--      );
--    END IF;
----
--    -- �\���`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT7 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT7) = '' ) THEN
--      -- �\���Z�O�����g����̏ꍇ�͗\�����̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08023'
--        )
--      );
--    END IF;
----
--    -- �ؕ��{�̋��z�����͂���Ă���ꍇ
--    IF ( xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR IS NOT NULL
--           OR TRIM(xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR) != '' ) THEN
----
--      -- ����Ŋz(DR)�`�F�b�N
--      IF ( xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR IS NULL 
--             OR TRIM(xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR) = '' ) THEN
--        -- �ؕ�����Ŋz����̏ꍇ�͏���Ŋz���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-14113'
--          )
--        );
--      END IF;
----
--      -- ����(DR)�`�F�b�N
--      IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR IS NULL 
--             OR TRIM(xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR) = '' ) THEN
--        -- �ؕ����ł���̏ꍇ�͓��œ��̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08022'
--          )
--        );
--      ELSE
--        -- ����(DR)���͒l�`�F�b�N
--        IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR != cv_yes
--               AND xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR != cv_no ) THEN
--          -- �ؕ����ł̓��͒l���s���̏ꍇ�͓��œ��͒l�G���[�\��
--          -- �X�e�[�^�X���G���[��
--          gv_result := cv_result_error;
--          -- �G���[�������Z
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-08027'
--            )
--          );
--        END IF;
--      END IF;
----
--      -- �ŋ敪(DR)�`�F�b�N
--      IF ( xx03_if_detail_rec.TAX_CODE_DR IS NULL 
--             OR TRIM(xx03_if_detail_rec.TAX_CODE_DR) = '' ) THEN
--        -- �ؕ��ŋ敪����̏ꍇ�͐ŋ敪���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-14111'
--          )
--        );
--      END IF;
----
--      -- ���Z�ϋ��z(DR)�`�F�b�N
--      IF xx03_if_header_rec.IGNORE_RATE_FLAG = 'N' THEN
--        IF ( xx03_if_detail_rec.ACCOUNTED_AMOUNT_DR IS NULL 
--               OR TRIM(xx03_if_detail_rec.ACCOUNTED_AMOUNT_DR) = '' ) THEN
--          -- �ؕ����Z�ϋ��z����̏ꍇ�͊��Z�ϋ��z���̓G���[�\��
--          -- �X�e�[�^�X���G���[��
--          gv_result := cv_result_error;
--          -- �G���[�������Z
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-11505'
--            )
--          );
--        END IF;
--      END IF;
----
--      -- �{�̋��z(CR)�`�F�b�N
--      IF ( xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR) != '' ) THEN
--        -- �ݕ��{�̋��z����łȂ��ꍇ�͑ݕ��{�̋��z���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11507'
--          )
--        );
--      END IF;
----
--      -- ����Ŋz(CR)�`�F�b�N
--      IF ( xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR) != '' ) THEN
--        -- �ݕ�����Ŋz����łȂ��ꍇ�͑ݕ�����Ŋz���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11508'
--          )
--        );
--      END IF;
----
--      -- �ŋ敪(CR)�`�F�b�N
--      IF ( xx03_if_detail_rec.TAX_CODE_CR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.TAX_CODE_CR) != '' ) THEN
--        -- �ݕ��ŋ敪����łȂ��ꍇ�͑ݕ��ŋ敪���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11510'
--          )
--        );
--      END IF;
----
--      -- ���Z�ϋ��z(CR)�`�F�b�N
--      IF ( xx03_if_detail_rec.ACCOUNTED_AMOUNT_CR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ACCOUNTED_AMOUNT_CR) != '' ) THEN
--        -- �ݕ����Z�ϋ��z����łȂ��ꍇ�͑ݕ����Z�ϋ��z���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11511'
--          )
--        );
--      END IF;
--    END IF;
----
--    IF ( xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR IS NOT NULL
--           OR TRIM(xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR) != '' ) THEN
----
--      -- ����Ŋz(CR)�`�F�b�N
--      IF ( xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR IS NULL 
--             OR TRIM(xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR) = '' ) THEN
--        -- �ݕ�����Ŋz����̏ꍇ�͏���Ŋz���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-14113'
--          )
--        );
--      END IF;
----
--      -- ����(CR)�`�F�b�N
--      IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR IS NULL 
--             OR TRIM(xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR) = '' ) THEN
--        -- �ݕ����ł���̏ꍇ�͓��œ��̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08022'
--          )
--        );
--      ELSE
--        -- ����(CR)���͒l�`�F�b�N
--        IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR != cv_yes
--               AND xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR != cv_no ) THEN
--          -- �ݕ����ł̓��͒l���s���̏ꍇ�͓��œ��͒l�G���[�\��
--          -- �X�e�[�^�X���G���[��
--          gv_result := cv_result_error;
--          -- �G���[�������Z
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-08027'
--            )
--          );
--        END IF;
--      END IF;
----
--      -- �ŋ敪(CR)�`�F�b�N
--      IF ( xx03_if_detail_rec.TAX_CODE_CR IS NULL 
--             OR TRIM(xx03_if_detail_rec.TAX_CODE_CR) = '' ) THEN
--        -- �ݕ��ŋ敪����̏ꍇ�͐ŋ敪���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-14111'
--          )
--        );
--      END IF;
----
--      -- ���Z�ϋ��z(CR)�`�F�b�N
--      IF xx03_if_header_rec.IGNORE_RATE_FLAG = 'N' THEN
--        IF ( xx03_if_detail_rec.ACCOUNTED_AMOUNT_CR IS NULL 
--               OR TRIM(xx03_if_detail_rec.ACCOUNTED_AMOUNT_CR) = '' ) THEN
--          -- �ݕ����Z�ϋ��z����̏ꍇ�͊��Z�ϋ��z���̓G���[�\��
--          -- �X�e�[�^�X���G���[��
--          gv_result := cv_result_error;
--          -- �G���[�������Z
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-11505'
--            )
--          );
--        END IF;
--      END IF;
----
--      -- �{�̋��z(DR)�`�F�b�N
--      IF ( xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR) != '' ) THEN
--        -- �ؕ��{�̋��z����łȂ��ꍇ�͎ؕ��{�̋��z���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11512'
--          )
--        );
--      END IF;
----
--      -- ����Ŋz(DR)�`�F�b�N
--      IF ( xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR) != '' ) THEN
--        -- �ؕ�����Ŋz����łȂ��ꍇ�͎ؕ�����Ŋz���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11513'
--          )
--        );
--      END IF;
----
--      -- �ŋ敪(DR)�`�F�b�N
--      IF ( xx03_if_detail_rec.TAX_CODE_DR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.TAX_CODE_DR) != '' ) THEN
--        -- �ؕ��ŋ敪����łȂ��ꍇ�͎ؕ��ŋ敪���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11515'
--          )
--        );
--      END IF;
----
--      -- ���Z�ϋ��z(DR)�`�F�b�N
--      IF ( xx03_if_detail_rec.ACCOUNTED_AMOUNT_DR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ACCOUNTED_AMOUNT_DR) != '' ) THEN
--        -- �ؕ����Z�ϋ��z����łȂ��ꍇ�͎ؕ����Z�ϋ��z���̓G���[�\��
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11516'
--          )
--        );
--      END IF;
--    END IF;
----
--  EXCEPTION
----
----#################################  �Œ��O������ START   ####################################
----
--    WHEN global_process_expt THEN   -- *** ���������ʗ�O�n���h�� ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END check_detail_data;
----
--  /**********************************************************************************
--   * Procedure Name   : copy_detail_data
--   * Description      : ���׃f�[�^�̃R�s�[(E-1)
--   ***********************************************************************************/
--  PROCEDURE copy_detail_data(
--    iv_source     IN  VARCHAR2,    --  1.�\�[�X
--    in_request_id IN  NUMBER,       -- 2.�v��ID
--    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'copy_detail_data'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
--    ln_line_id NUMBER;     -- ����ID
--    ln_line_count NUMBER;  -- ���טA��
--    ln_line_count_cr NUMBER; -- �ݕ����טA��
--    ln_line_count_dr NUMBER; -- �ؕ����טA��
--    ln_amount_dr NUMBER;   -- ���z
--    ln_amount_cr NUMBER;   -- ���z
--    lv_amount_includes_tax_flag_dr VARCHAR2(100); -- ���ŋ敪
--    lv_amount_includes_tax_flag_cr VARCHAR2(100); -- ���ŋ敪
--    lv_currency_code VARCHAR2(4000); -- �@�\�ʉ݃R�[�h
--    ln_total_accounted_dr NUMBER;  -- ���Z�ύ��v���z
--    ln_total_accounted_cr NUMBER;  -- ���Z�ύ��v���z
----
--    -- ===============================
--    -- ���[�J���E�J�[�\��
--    -- ===============================
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  �Œ蕔 END   ############################
----
--    -- ***************************************
--    -- ***        �������̋L�q             ***
--    -- ***       ���ʊ֐��̌Ăяo��        ***
--    -- ***************************************
----
----
--   -- �@�\�ʉ݃R�[�h�擾
--   SELECT gsob.currency_code
--     INTO lv_currency_code
--     FROM gl_sets_of_books gsob
--    WHERE gsob.set_of_books_id = xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
----
--    -- ���טA�ԏ�����
--    ln_line_count    := 1;
--    ln_line_count_cr := 1;
--    ln_line_count_dr := 1;
----
--    -- ���׏��J�[�\���I�[�v��
--    OPEN xx03_if_detail_cur(iv_source,
--                            in_request_id, 
--                            xx03_if_header_rec.INTERFACE_ID, 
--                            xx03_if_header_rec.INVOICE_CURRENCY_CODE,
--                            lv_currency_code);
--    <<xx03_if_detail_loop>>
--    LOOP
--      FETCH xx03_if_detail_cur INTO xx03_if_detail_rec;
--      IF xx03_if_detail_cur%NOTFOUND THEN
--        -- �Ώۃf�[�^���Ȃ��Ȃ�܂Ń��[�v
--        EXIT xx03_if_detail_loop;
--      END IF;
----
--      -- ===============================
--      -- ���̓`�F�b�N(E-2)
--      -- ===============================
--      check_detail_data(
--        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
--        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
--        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--        RAISE global_process_expt;
--      END IF;
----
--      -- ����ID�擾
--      SELECT XX03_JOURNAL_SLIP_LINES_S.nextval 
--        INTO ln_line_id
--        FROM dual;
----
--      -- ���z�Z�o
--      IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR = cv_yes ) THEN
--        -- '����'��'Y'�̎��͋��z��'�{�̋��z+����Ŋz'
--        ln_amount_dr := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR + 
--                        xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR;
--      ELSIF  ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR = cv_no ) THEN
--        -- '����'��'N'�̎��͋��z��'�{�̋��z'
--        ln_amount_dr := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR;
--      ELSE
--        -- ����ȊO�̎��͓��œ��͒l�G���[
--        ln_amount_dr := 0;
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08027'
--          )
--        );
--      END IF;
----
--      -- ���z�Z�o
--      IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR = cv_yes ) THEN
--        -- '����'��'Y'�̎��͋��z��'�{�̋��z+����Ŋz'
--        ln_amount_cr := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR + 
--                        xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR;
--      ELSIF  ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR = cv_no ) THEN
--        -- '����'��'N'�̎��͋��z��'�{�̋��z'
--        ln_amount_cr := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR;
--      ELSE
--        -- ����ȊO�̎��͓��œ��͒l�G���[
--        ln_amount_cr := 0;
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08027'
--          )
--        );
--      END IF;
----
--      -- ���ŋ敪
--      IF xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR IS NULL THEN
--        lv_amount_includes_tax_flag_dr := NULL;
--      ELSE
--        lv_amount_includes_tax_flag_dr := xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR;
--      END IF;
--      IF xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR IS NULL THEN
--        lv_amount_includes_tax_flag_cr := NULL;
--      ELSE
--        lv_amount_includes_tax_flag_cr := xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR;
--      END IF;
----
--      -- ���׃f�[�^�ۑ�
--      INSERT INTO XX03_JOURNAL_SLIP_LINES(
--        JOURNAL_LINE_ID             ,
--        JOURNAL_ID                  ,
--        LINE_NUMBER                 ,
--        SLIP_LINE_TYPE_DR           ,
--        SLIP_LINE_TYPE_NAME_DR      ,
--        ENTERED_AMOUNT_DR           ,
--        ENTERED_ITEM_AMOUNT_DR      ,
--        AMOUNT_INCLUDES_TAX_FLAG_DR ,
--        TAX_CODE_DR                 ,
--        TAX_NAME_DR                 ,
--        ENTERED_TAX_AMOUNT_DR       ,
--        ACCOUNTED_AMOUNT_DR         ,
--        SLIP_LINE_TYPE_CR           ,
--        SLIP_LINE_TYPE_NAME_CR      ,
--        ENTERED_AMOUNT_CR           ,
--        ENTERED_ITEM_AMOUNT_CR      ,
--        AMOUNT_INCLUDES_TAX_FLAG_CR ,
--        TAX_CODE_CR                 ,
--        TAX_NAME_CR                 ,
--        ENTERED_TAX_AMOUNT_CR       ,
--        ACCOUNTED_AMOUNT_CR         ,
--        DESCRIPTION                 ,
--        SEGMENT1                    ,
--        SEGMENT2                    ,
--        SEGMENT3                    ,
--        SEGMENT4                    ,
--        SEGMENT5                    ,
--        SEGMENT6                    ,
--        SEGMENT7                    ,
--        SEGMENT8                    ,
--        SEGMENT9                    ,
--        SEGMENT10                   ,
--        SEGMENT11                   ,
--        SEGMENT12                   ,
--        SEGMENT13                   ,
--        SEGMENT14                   ,
--        SEGMENT15                   ,
--        SEGMENT16                   ,
--        SEGMENT17                   ,
--        SEGMENT18                   ,
--        SEGMENT19                   ,
--        SEGMENT20                   ,
--        SEGMENT1_NAME               ,
--        SEGMENT2_NAME               ,
--        SEGMENT3_NAME               ,
--        SEGMENT4_NAME               ,
--        SEGMENT5_NAME               ,
--        SEGMENT6_NAME               ,
--        SEGMENT7_NAME               ,
--        SEGMENT8_NAME               ,
--        INCR_DECR_REASON_CODE       ,
--        INCR_DECR_REASON_NAME       ,
--        RECON_REFERENCE             ,
--        ORG_ID                      ,
--        ATTRIBUTE_CATEGORY          ,
--        ATTRIBUTE1                  ,
--        ATTRIBUTE2                  ,
--        ATTRIBUTE3                  ,
--        ATTRIBUTE4                  ,
--        ATTRIBUTE5                  ,
--        ATTRIBUTE6                  ,
--        ATTRIBUTE7                  ,
--        ATTRIBUTE8                  ,
--        ATTRIBUTE9                  ,
--        ATTRIBUTE10                 ,
--        ATTRIBUTE11                 ,
--        ATTRIBUTE12                 ,
--        ATTRIBUTE13                 ,
--        ATTRIBUTE14                 ,
--        ATTRIBUTE15                 ,
--        CREATED_BY                  ,
--        CREATION_DATE               ,
--        LAST_UPDATED_BY             ,
--        LAST_UPDATE_DATE            ,
--        LAST_UPDATE_LOGIN           ,
--        REQUEST_ID                  ,
--        PROGRAM_APPLICATION_ID      ,
--        PROGRAM_ID                  ,
--        PROGRAM_UPDATE_DATE       
--      )
--      VALUES(
--        ln_line_id,
--        gn_journal_id,
--        DECODE(xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR, NULL, ln_line_count_dr, ln_line_count_cr),
--        NULL,
--        NULL,
--        ln_amount_dr,
--        xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR,
--        lv_amount_includes_tax_flag_dr,
--        xx03_if_detail_rec.TAX_CODE_DR,
--        xx03_if_detail_rec.TAX_NAME_DR,
--        xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR,
--        xx03_if_detail_rec.ACCOUNTED_AMOUNT_DR,
--        NULL,
--        NULL,
--        ln_amount_cr,
--        xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR,
--        lv_amount_includes_tax_flag_cr,
--        xx03_if_detail_rec.TAX_CODE_CR,
--        xx03_if_detail_rec.TAX_NAME_CR,
--        xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR,
--        xx03_if_detail_rec.ACCOUNTED_AMOUNT_CR,
--        xx03_if_detail_rec.DESCRIPTION,
--        xx03_if_detail_rec.SEGMENT1,
--        xx03_if_detail_rec.SEGMENT2,
--        xx03_if_detail_rec.SEGMENT3,
--        xx03_if_detail_rec.SEGMENT4,
--        xx03_if_detail_rec.SEGMENT5,
--        xx03_if_detail_rec.SEGMENT6,
--        xx03_if_detail_rec.SEGMENT7,
--        xx03_if_detail_rec.SEGMENT8,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        xx03_if_detail_rec.SEGMENT1_NAME,
--        xx03_if_detail_rec.SEGMENT2_NAME,
--        xx03_if_detail_rec.SEGMENT3_NAME,
--        xx03_if_detail_rec.SEGMENT4_NAME,
--        xx03_if_detail_rec.SEGMENT5_NAME,
--        xx03_if_detail_rec.SEGMENT6_NAME,
--        xx03_if_detail_rec.SEGMENT7_NAME,
--        xx03_if_detail_rec.SEGMENT8_NAME,
--        xx03_if_detail_rec.INCR_DECR_REASON_CODE,
--        xx03_if_detail_rec.INCR_DECR_REASON_NAME,
--        xx03_if_detail_rec.RECON_REFERENCE,
--        xx03_if_detail_rec.ORG_ID,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        xx00_global_pkg.user_id,
--        xx00_date_pkg.get_system_datetime_f,
--        xx00_global_pkg.user_id,
--        xx00_date_pkg.get_system_datetime_f,
--        xx00_global_pkg.login_id,
--        xx00_global_pkg.conc_request_id,
--        xx00_global_pkg.prog_appl_id,
--        xx00_global_pkg.conc_program_id,
--        xx00_date_pkg.get_system_datetime_f
--      );
----
--      -- ���טA�ԉ��Z
--      IF xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR IS NOT NULL THEN
--        ln_line_count_dr := ln_line_count_dr + 1;
--      ELSIF xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR IS NOT NULL THEN
--        ln_line_count_cr := ln_line_count_cr + 1;
--      ELSE
--        ln_line_count := ln_line_count + 1;
--      END IF;
----
--    END LOOP xx03_if_detail_loop;
--    CLOSE xx03_if_detail_cur;
----
--    IF xx03_if_header_rec.IGNORE_RATE_FLAG = cv_no THEN
--      -- ���Z�ϋ��z���v
--      SELECT SUM(xjsl.ACCOUNTED_AMOUNT_DR) as ACCOUNTED_AMOUNT_DR,
--             SUM(xjsl.ACCOUNTED_AMOUNT_CR) as ACCOUNTED_AMOUNT_CR
--        INTO ln_total_accounted_dr,
--             ln_total_accounted_cr
--        FROM XX03_JOURNAL_SLIP_LINES xjsl
--       WHERE xjsl.JOURNAL_ID = gn_journal_id
--      GROUP BY xjsl.JOURNAL_ID;
--      IF ln_total_accounted_dr != ln_total_accounted_cr THEN
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-03036'
--          )
--        );
--      END IF;
--    END IF;
----
--  EXCEPTION
----
----#################################  �Œ��O������ START   ####################################
----
--    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END copy_detail_data;
----
--  /**********************************************************************************
--   * Procedure Name   : check_header_data
--   * Description      : �d��`�[�f�[�^�̓��̓`�F�b�N(E-2)
--   ***********************************************************************************/
--  PROCEDURE check_header_data(
--    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
--    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
--    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_header_data'; -- �v���O������
----
----#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  �Œ蕔 END   ############################
----
--    -- �`�[��ʃ`�F�b�N
--    IF ( xx03_if_header_rec.SLIP_TYPE IS NULL 
--           OR TRIM(xx03_if_header_rec.SLIP_TYPE) = '' ) THEN
--      -- �`�[���ID����̏ꍇ�͓`�[��ʓ��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08010'
--        )
--      );
--    END IF;
----
--    -- ���F�҃`�F�b�N
--    IF ( xx03_if_header_rec.APPROVER_PERSON_NAME IS NULL 
--           OR TRIM(xx03_if_header_rec.APPROVER_PERSON_NAME) = '' ) THEN
--      -- ���F�Җ�����̏ꍇ�͏��F�ғ��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08011'
--        )
--      );
--    END IF;
----
--    -- �v����`�F�b�N
--    IF ( xx03_if_header_rec.GL_DATE IS NULL 
--           OR TRIM(xx03_if_header_rec.GL_DATE) = '' ) THEN
--      -- �v�������̏ꍇ�͌v������̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08015'
--        )
--      );
--    END IF;
----
--    -- ��v���ԃ`�F�b�N
--    IF ( xx03_if_header_rec.PERIOD_NAME IS NULL 
--           OR TRIM(xx03_if_header_rec.PERIOD_NAME) = '' ) THEN
--      -- ��v���Ԃ���̏ꍇ�͉�v���ԓ��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08028'
--        )
--      );
--    END IF;
----
--    -- �ʉ݃`�F�b�N
--    IF ( xx03_if_header_rec.INVOICE_CURRENCY_CODE IS NULL 
--           OR TRIM(xx03_if_header_rec.INVOICE_CURRENCY_CODE) = '' ) THEN
--      -- �ʉ݂���̏ꍇ�͒ʉݓ��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08018'
--        )
--      );
--    END IF;
----
--    -- ���[�g�^�C�v�`�F�b�N
--    IF ( xx03_if_header_rec.EXCHANGE_RATE_TYPE_NAME IS NOT NULL 
--           AND ( xx03_if_header_rec.EXCHANGE_RATE_TYPE IS NULL 
--           OR TRIM(xx03_if_header_rec.EXCHANGE_RATE_TYPE) = '' )) THEN
--      -- ���[�g�^�C�v�R�[�h���擾�ł��Ȃ������ꍇ�̓��[�g�^�C�v���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08025'
--        )
--      );
--    END IF;
----
--  EXCEPTION
----
----#################################  �Œ��O������ START   ####################################
----
--    WHEN global_process_expt THEN   -- *** ���������ʗ�O�n���h�� ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END check_header_data;
----
--  /**********************************************************************************
--   * Procedure Name   : calc_amount
--   * Description      : ���z�v�Z(E-3)
--   ***********************************************************************************/
--  PROCEDURE calc_amount(
--    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
--    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
--    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_amount'; -- �v���O������
----
----#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
--    ln_total_item_amount_dr NUMBER; -- �{�̋��z���v
--    ln_total_tax_amount_dr NUMBER;  -- ����Ŋz���v
--    ln_total_amount_dr NUMBER;      -- ���׍��v���z
--    ln_total_accounted_dr NUMBER;   -- ���Z�ύ��v���z
--    ln_total_item_amount_cr NUMBER; -- �{�̋��z���v
--    ln_total_tax_amount_cr NUMBER;  -- ����Ŋz���v
--    ln_total_amount_cr NUMBER;      -- ���׍��v���z
--    ln_total_accounted_cr NUMBER;   -- ���Z�ύ��v���z
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  �Œ蕔 END   ############################
----
--    -- �{�̋��z���v�Z�o
--    SELECT SUM(xjsl.ENTERED_ITEM_AMOUNT_DR) as ENTERED_ITEM_AMOUNT_DR,
--           SUM(xjsl.ENTERED_ITEM_AMOUNT_CR) as ENTERED_ITEM_AMOUNT_CR
--      INTO ln_total_item_amount_dr,
--           ln_total_item_amount_cr
--      FROM XX03_JOURNAL_SLIP_LINES xjsl
--     WHERE xjsl.JOURNAL_ID = gn_journal_id
--    GROUP BY xjsl.JOURNAL_ID;
----
--    -- �w�b�_���R�[�h�ɖ{�̍��v���z�Z�b�g
--    UPDATE XX03_JOURNAL_SLIPS xjs 
--       SET xjs.TOTAL_ITEM_ENTERED_DR = ln_total_item_amount_dr,
--           xjs.TOTAL_ITEM_ENTERED_CR = ln_total_item_amount_cr
--     WHERE xjs.JOURNAL_ID = gn_journal_id;
----
--    -- ����Ŋz���v
--    SELECT SUM(xjsl.ENTERED_TAX_AMOUNT_DR) as ENTERED_TAX_AMOUNT_DR,
--           SUM(xjsl.ENTERED_TAX_AMOUNT_CR) as ENTERED_TAX_AMOUNT_CR
--      INTO ln_total_tax_amount_dr,
--           ln_total_tax_amount_cr
--      FROM XX03_JOURNAL_SLIP_LINES xjsl
--     WHERE xjsl.JOURNAL_ID = gn_journal_id
--    GROUP BY xjsl.JOURNAL_ID;
----
--    -- �w�b�_���R�[�h�ɏ���ŋ��z�Z�b�g
--    UPDATE XX03_JOURNAL_SLIPS xjs 
--       SET xjs.TOTAL_TAX_ENTERED_DR = ln_total_tax_amount_dr,
--           xjs.TOTAL_TAX_ENTERED_CR = ln_total_tax_amount_cr
--     WHERE xjs.JOURNAL_ID = gn_journal_id;
----
--   -- ���v���z���v
--   SELECT SUM(xjsl.ENTERED_ITEM_AMOUNT_DR+xjsl.ENTERED_TAX_AMOUNT_DR) as ENTERED_AMOUNT_DR,
--          SUM(xjsl.ENTERED_ITEM_AMOUNT_CR+xjsl.ENTERED_TAX_AMOUNT_CR) as ENTERED_AMOUNT_CR
--      INTO ln_total_amount_dr,
--           ln_total_amount_cr
--      FROM XX03_JOURNAL_SLIP_LINES xjsl
--     WHERE xjsl.JOURNAL_ID = gn_journal_id
--    GROUP BY xjsl.JOURNAL_ID;
----
--    -- �w�b�_���R�[�h�ɖ��׍��v���z�Z�b�g
--    UPDATE XX03_JOURNAL_SLIPS xjs 
--       SET xjs.TOTAL_ENTERED_DR = ln_total_amount_dr,
--           xjs.TOTAL_ENTERED_CR = ln_total_amount_cr
--     WHERE xjs.JOURNAL_ID = gn_journal_id;
----
--    -- ���Z�ϋ��z���v
--    SELECT SUM(xjsl.ACCOUNTED_AMOUNT_DR) as ACCOUNTED_AMOUNT_DR,
--           SUM(xjsl.ACCOUNTED_AMOUNT_CR) as ACCOUNTED_AMOUNT_CR
--      INTO ln_total_accounted_dr,
--           ln_total_accounted_cr
--      FROM XX03_JOURNAL_SLIP_LINES xjsl
--     WHERE xjsl.JOURNAL_ID = gn_journal_id
--    GROUP BY xjsl.JOURNAL_ID;
----
--    -- �w�b�_�[���R�[�h�Ɋ��Z�ϋ��z���v���Z�b�g
--    UPDATE XX03_JOURNAL_SLIPS xjs 
--       SET xjs.TOTAL_ACCOUNTED_DR = ln_total_accounted_dr,
--           xjs.TOTAL_ACCOUNTED_CR = ln_total_accounted_cr
--     WHERE xjs.JOURNAL_ID = gn_journal_id;
----
--  EXCEPTION
----
----#################################  �Œ��O������ START   ####################################
----
--    WHEN global_process_expt THEN   -- *** ���������ʗ�O�n���h�� ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END calc_amount;
----
--  /**********************************************************************************
--   * Procedure Name   : copy_if_data
--   * Description      : �C���^�[�t�F�[�X�f�[�^�̃R�s�[(E-1)
--   ***********************************************************************************/
--  PROCEDURE copy_if_data(
--    iv_source     IN  VARCHAR2,     -- 1.�\�[�X
--    in_request_id IN  NUMBER,       -- 2.�v��ID
--    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'copy_if_data'; -- �v���O������
----
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
----###########################  �Œ蕔 END   ####################################
----
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
----
--    -- *** ���[�J���ϐ� ***
--    ln_interface_id NUMBER;         -- INTERFACE_ID
--    ln_header_count NUMBER;         -- INTERFACE_ID����l�w�b�_����
--    ld_terms_date DATE;             -- �x���\���
--    lv_terms_flg VARCHAR2(1);       -- �x���\����ύX�\�t���O
--    lv_app_upd VARCHAR2(1);         -- �d�_�Ǘ��t���O
--    ln_error_cnt NUMBER;            -- �d��`�F�b�N�G���[����
--    lv_error_flg VARCHAR2(1);       -- �d��`�F�b�N�G���[�t���O
--    lv_error_flg1 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O1
--    lv_error_msg1 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W1
--    lv_error_flg2 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O2
--    lv_error_msg2 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W2
--    lv_error_flg3 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O3
--    lv_error_msg3 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W3
--    lv_error_flg4 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O4
--    lv_error_msg4 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W4
--    lv_error_flg5 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O5
--    lv_error_msg5 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W5
--    lv_error_flg6 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O6
--    lv_error_msg6 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W6
--    lv_error_flg7 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O7
--    lv_error_msg7 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W7
--    lv_error_flg8 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O8
--    lv_error_msg8 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W8
--    lv_error_flg9 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O9
--    lv_error_msg9 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W9
--    lv_error_flg10 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O10
--    lv_error_msg10 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W10
--    lv_error_flg11 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O11
--    lv_error_msg11 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W11
--    lv_error_flg12 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O12
--    lv_error_msg12 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W12
--    lv_error_flg13 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O13
--    lv_error_msg13 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W13
--    lv_error_flg14 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O14
--    lv_error_msg14 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W14
--    lv_error_flg15 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O15
--    lv_error_msg15 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W15
--    lv_error_flg16 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O16
--    lv_error_msg16 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W16
--    lv_error_flg17 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O17
--    lv_error_msg17 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W17
--    lv_error_flg18 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O18
--    lv_error_msg18 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W18
--    lv_error_flg19 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O19
--    lv_error_msg19 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W19
--    lv_error_flg20 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O20
--    lv_error_msg20 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W20
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  �Œ蕔 END   ############################
----
--    -- ***************************************
--    -- ***        �������̋L�q             ***
--    -- ***       ���ʊ֐��̌Ăяo��        ***
--    -- ***************************************
----
--    -- �X�e�[�^�X������
--    gv_result := cv_result_normal;
--    ln_interface_id := NULL;
----
--    -- �w�b�_���J�[�\���I�[�v��
--    OPEN xx03_if_header_cur(iv_source, in_request_id);
--    <<xx03_if_header_loop>>
--    LOOP
--      -- �G���[����������
--      gn_error_count := 0;
----
--      FETCH xx03_if_header_cur INTO xx03_if_header_rec;
--      IF xx03_if_header_cur%NOTFOUND THEN
--        -- �Ώۃf�[�^���Ȃ��Ȃ�܂Ń��[�v
--        EXIT xx03_if_header_loop;
--      END IF;
----
--      -- INTERFACE_ID����l�����w�b�_�����擾
--      SELECT COUNT(xjsi.INTERFACE_ID)
--        INTO ln_header_count
--        FROM XX03_JOURNAL_SLIPS_IF xjsi
--       WHERE xjsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID
--         AND xjsi.REQUEST_ID = in_request_id
--         AND xjsi.SOURCE = iv_source;
----
--      -- INTERFACE_ID����l�w�b�_���P���̎��̂݌㑱�̏������s��
--      IF ( ln_header_count > 1 ) THEN
--        -- INTERFACE_ID����l�w�b�_���Q���ȏ�
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        IF ( ln_interface_id IS NULL 
--             OR ln_interface_id <> xx03_if_header_rec.INTERFACE_ID ) THEN
--          -- ���oID�̏ꍇ�̓G���[���o��
--          -- INTERFACE_ID�o��
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-08008',
--              'TOK_XX03_INTERFACE_ID',
--              xx03_if_header_rec.INTERFACE_ID
--            )
--          );
--          -- �G���[���o��
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-08006'
--            )
--          );
--        END IF;
--      ELSE
----
--        -- INTERFACE_ID�o��
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08008',
--            'TOK_XX03_INTERFACE_ID',
--            xx03_if_header_rec.INTERFACE_ID
--          )
--        );
----
--        -- ===============================
--        -- ���̓`�F�b�N(E-2)
--        -- ===============================
--        check_header_data(
--          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
--          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
--          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--          RAISE global_process_expt;
--        END IF;
----
--        -- �G���[�����o����Ă��Ȃ����݈̂ȍ~�̏������s
--        IF ( gn_error_count = 0 ) THEN
----
--          -- �`�[ID�擾
--          SELECT XX03_JOURNAL_SLIPS_S.nextval 
--            INTO gn_journal_id
--            FROM dual;
----
--          -- �C���^�[�t�F�[�X�e�[�u���`�[ID�X�V
--          UPDATE XX03_JOURNAL_SLIPS_IF xjsi
--             SET JOURNAL_ID = gn_journal_id
--           WHERE xjsi.REQUEST_ID = in_request_id
--             AND xjsi.SOURCE = iv_source
--             AND xjsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID;
----
--          -- �w�b�_�f�[�^�ۑ�
--          INSERT INTO XX03_JOURNAL_SLIPS(
--            JOURNAL_ID                   ,
--            WF_STATUS                    ,
--            SLIP_TYPE                    ,
--            JOURNAL_NUM                  ,
--            ENTRY_DATE                   ,
--            REQUEST_KEY                  ,
--            REQUESTOR_PERSON_ID          ,
--            REQUESTOR_PERSON_NAME        ,
--            APPROVER_PERSON_ID           ,
--            APPROVER_PERSON_NAME         ,
--            REQUEST_DATE                 ,
--            APPROVAL_DATE                ,
--            REJECTION_DATE               ,
--            ACCOUNT_APPROVER_PERSON_ID   ,
--            ACCOUNT_APPROVAL_DATE        ,
--            GL_FORWORD_DATE              ,
--            RECOGNITION_CLASS            ,
--            APPROVER_COMMENTS            ,
--            REQUEST_ENABLE_FLAG          ,
--            ACCOUNT_REVISION_FLAG        ,
--            TOTAL_ENTERED_DR             ,
--            TOTAL_ACCOUNTED_DR           ,
--            TOTAL_ITEM_ENTERED_DR        ,
--            TOTAL_TAX_ENTERED_DR         ,
--            TOTAL_ENTERED_CR             ,
--            TOTAL_ACCOUNTED_CR           ,
--            TOTAL_ITEM_ENTERED_CR        ,
--            TOTAL_TAX_ENTERED_CR         ,
--            INVOICE_CURRENCY_CODE        ,
--            EXCHANGE_RATE                ,
--            EXCHANGE_RATE_TYPE           ,
--            EXCHANGE_RATE_TYPE_NAME      ,
--            IGNORE_RATE_FLAG             ,
--            DESCRIPTION                  ,
--            ENTRY_DEPARTMENT             ,
--            ENTRY_PERSON_ID              ,
--            ORIG_JOURNAL_NUM             ,
--            ACCOUNT_APPROVAL_FLAG        ,
--            PERIOD_NAME                  ,
--            GL_DATE                      ,
--            AUTO_TAX_CALC_FLAG           ,
--            AP_TAX_ROUNDING_RULE         ,
--            FORM_SELECT_FLAG             ,
--            ORG_ID                       ,
--            SET_OF_BOOKS_ID              ,
--            RECURRING_HEADER_NAME        ,
--            ATTRIBUTE_CATEGORY           ,
--            ATTRIBUTE1                   ,
--            ATTRIBUTE2                   ,
--            ATTRIBUTE3                   ,
--            ATTRIBUTE4                   ,
--            ATTRIBUTE5                   ,
--            ATTRIBUTE6                   ,
--            ATTRIBUTE7                   ,
--            ATTRIBUTE8                   ,
--            ATTRIBUTE9                   ,
--            ATTRIBUTE10                  ,
--            ATTRIBUTE11                  ,
--            ATTRIBUTE12                  ,
--            ATTRIBUTE13                  ,
--            ATTRIBUTE14                  ,
--            ATTRIBUTE15                  ,
--            CREATED_BY                   ,
--            CREATION_DATE                ,
--            LAST_UPDATED_BY              ,
--            LAST_UPDATE_DATE             ,
--            LAST_UPDATE_LOGIN            ,
--            REQUEST_ID                   ,
--            PROGRAM_APPLICATION_ID       ,
--            PROGRAM_UPDATE_DATE          ,
--            PROGRAM_ID                  
--          )
--          VALUES(
--            gn_journal_id,
--            xx03_if_header_rec.WF_STATUS,
--            xx03_if_header_rec.SLIP_TYPE,
--            gn_journal_id,
--            xx03_if_header_rec.ENTRY_DATE,
--            NULL,
--            xx03_if_header_rec.REQUESTOR_PERSON_ID,
--            xx03_if_header_rec.REQUESTOR_PERSON_NAME,
--            xx03_if_header_rec.APPROVER_PERSON_ID,
--            xx03_if_header_rec.APPROVER_PERSON_NAME,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            0,
--            NULL,
--            'N',
--            'N',
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            xx03_if_header_rec.INVOICE_CURRENCY_CODE,
--            xx03_if_header_rec.EXCHANGE_RATE,
--            xx03_if_header_rec.EXCHANGE_RATE_TYPE,
--            xx03_if_header_rec.EXCHANGE_RATE_TYPE_NAME,
--            xx03_if_header_rec.IGNORE_RATE_FLAG,
--            xx03_if_header_rec.DESCRIPTION,
--            xx03_if_header_rec.ENTRY_DEPARTMENT,
--            xx03_if_header_rec.ENTRY_PERSON_ID,
--            NULL,
--            'N',
--            xx03_if_header_rec.PERIOD_NAME,
--            xx03_if_header_rec.GL_DATE,
--            xx03_if_header_rec.AUTO_TAX_CALC_FLAG,
--            xx03_if_header_rec.AP_TAX_ROUNDING_RULE,
--            NULL,
--            xx03_if_header_rec.ORG_ID,
--            xx03_if_header_rec.SET_OF_BOOKS_ID,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            xx00_global_pkg.user_id,
--            xx00_date_pkg.get_system_datetime_f,
--            xx00_global_pkg.user_id,
--            xx00_date_pkg.get_system_datetime_f,
--            xx00_global_pkg.login_id,
--            xx00_global_pkg.conc_request_id,
--            xx00_global_pkg.prog_appl_id,
--            xx00_date_pkg.get_system_datetime_f,
--            xx00_global_pkg.conc_program_id
--          );
----
--          -- ===============================
--          -- ���׃f�[�^�R�s�[
--          -- ===============================
--          copy_detail_data(
--            iv_source,         -- �\�[�X
--            in_request_id,     -- �v��ID
--            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
--            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
--            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--            RAISE global_process_expt;
--          END IF;
----
--          -- ===============================
--          -- ���z�v�Z(E-3)
--          -- ===============================
--          calc_amount(
--            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
--            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
--            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--            RAISE global_process_expt;
--          END IF;
----
--          -- ===============================
--          -- �d�_�Ǘ��`�F�b�N(E-4)
--          -- ===============================
--          xx03_deptinput_gl_check_pkg.set_account_approval_flag(
--            gn_journal_id,
--            lv_app_upd,
--            lv_errbuf,
--            lv_retcode,
--            lv_errmsg
--          );
--          IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--            -- ���ʂ�����Ȃ�A�w�b�_���R�[�h�̏d�_�Ǘ��t���O���X�V
--            UPDATE XX03_JOURNAL_SLIPS xjs 
--               SET xjs.ACCOUNT_APPROVAL_FLAG = lv_app_upd
--             WHERE xjs.JOURNAL_ID = gn_journal_id;
--          ELSE
--            -- ���ʂ�����łȂ���΁A�G���[���b�Z�[�W���o��
--            -- �X�e�[�^�X�����݂̒l���X�ɏ�ʂ̒l�̎��͏㏑��
--            IF ( TO_NUMBER(lv_retcode) > TO_NUMBER(gv_result)  ) THEN
--              gv_result := lv_retcode;
--            END IF;
--            -- �G���[�������Z
--            gn_error_count := gn_error_count + 1;
--            xx00_file_pkg.output(
--              xx00_message_pkg.get_msg(
--                'XX03',
--                'APP-XX03-14143'
--              )
--            );
--          END IF;
----
--          -- ===============================
--          -- �d��`�F�b�N(E-5)
--          -- ===============================
--          xx03_deptinput_gl_check_pkg. check_deptinput_gl (
--            gn_journal_id,
--            ln_error_cnt,
--            lv_error_flg,
--            lv_error_flg1,
--            lv_error_msg1,
--            lv_error_flg2,
--            lv_error_msg2,
--            lv_error_flg3,
--            lv_error_msg3,
--            lv_error_flg4,
--            lv_error_msg4,
--            lv_error_flg5,
--            lv_error_msg5,
--            lv_error_flg6,
--            lv_error_msg6,
--            lv_error_flg7,
--            lv_error_msg7,
--            lv_error_flg8,
--            lv_error_msg8,
--            lv_error_flg9,
--            lv_error_msg9,
--            lv_error_flg10,
--            lv_error_msg10,
--            lv_error_flg11,
--            lv_error_msg11,
--            lv_error_flg12,
--            lv_error_msg12,
--            lv_error_flg13,
--            lv_error_msg13,
--            lv_error_flg14,
--            lv_error_msg14,
--            lv_error_flg15,
--            lv_error_msg15,
--            lv_error_flg16,
--            lv_error_msg16,
--            lv_error_flg17,
--            lv_error_msg17,
--            lv_error_flg18,
--            lv_error_msg18,
--            lv_error_flg19,
--            lv_error_msg19,
--            lv_error_flg20,
--            lv_error_msg20,
--            lv_errbuf,
--            lv_retcode,
--            lv_errmsg
--          );
--          IF ( ln_error_cnt > 0 ) THEN
--            -- �X�e�[�^�X�����݂̒l���X�ɏ�ʂ̒l�̎��͏㏑��
--            IF ( gv_result = cv_result_normal AND lv_error_flg = cv_dept_warning ) THEN
--              gv_result := cv_result_warning;
--            ELSIF ( lv_error_flg = cv_dept_error ) THEN
--              gv_result := cv_result_error;
--            END IF;
--            -- �d��G���[�L�莞�́A���݂��镪�S�ăG���[���b�Z�[�W���o��
--            IF ( lv_error_flg1 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--               xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg1
--                )
--              );
--            END IF;
--            IF ( lv_error_flg2 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg2
--                )
--              );
--            END IF;
--            IF ( lv_error_flg3 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg3
--                )
--              );
--            END IF;
--            IF ( lv_error_flg4 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg4
--                )
--              );
--            END IF;
--            IF ( lv_error_flg5 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg5
--                )
--              );
--            END IF;
--            IF ( lv_error_flg6 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg6
--                )
--              );
--            END IF;
--            IF ( lv_error_flg7 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg7
--                )
--              );
--            END IF;
--            IF ( lv_error_flg8 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg8
--                )
--              );
--            END IF;
--            IF ( lv_error_flg9 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg9
--                )
--              );
--            END IF;
--            IF ( lv_error_flg10 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg10
--                )
--              );
--            END IF;
--            IF ( lv_error_flg11 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg11
--                )
--              );
--            END IF;
--            IF ( lv_error_flg12 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg12
--                )
--              );
--            END IF;
--            IF ( lv_error_flg13 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg13
--                )
--              );
--            END IF;
--            IF ( lv_error_flg14 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg14
--                )
--              );
--            END IF;
--            IF ( lv_error_flg15 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg15
--                )
--              );
--            END IF;
--            IF ( lv_error_flg16 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg16
--                )
--              );
--            END IF;
--            IF ( lv_error_flg17 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg17
--                )
--              );
--            END IF;
--            IF ( lv_error_flg18 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg18
--                )
--              );
--            END IF;
--            IF ( lv_error_flg19 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg19
--                )
--              );
--            END IF;
--            IF ( lv_error_flg20 <> cv_dept_normal ) THEN
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg20
--                )
--              );
--            END IF;
--          END IF;
--        END IF;
--      END IF;
----
--      -- INTERFACE_ID�ۑ�
--      ln_interface_id := xx03_if_header_rec.INTERFACE_ID;
----
--      -- �G���[���Ȃ������ꍇ��'�G���[�Ȃ�'�o��
--      IF ( gn_error_count = 0 ) THEN
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08020'
--          )
--        );
--      END IF;
----
--    END LOOP xx03_if_header_loop;
--    CLOSE xx03_if_header_cur;
----
--  EXCEPTION
----
----#################################  �Œ��O������ START   ####################################
----
--    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
----
----#####################################  �Œ蕔 END   ##########################################
----
--  END copy_if_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_header_data
   * Description      : �w�b�_�f�[�^�̃R�s�[
   ***********************************************************************************/
  PROCEDURE ins_header_data(
    iv_source     IN  VARCHAR2,     --  1.�\�[�X
    in_request_id IN  NUMBER,       --  2.�v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_header_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- �`�[ID�擾
    SELECT XX03_JOURNAL_SLIPS_S.nextval
    INTO   gn_journal_id
    FROM   dual;
--
    -- �C���^�[�t�F�[�X�e�[�u���`�[ID�X�V
    UPDATE XX03_JOURNAL_SLIPS_IF xjsi
       SET JOURNAL_ID = gn_journal_id
    WHERE  xjsi.REQUEST_ID   = in_request_id
      AND  xjsi.SOURCE       = iv_source
      AND  xjsi.INTERFACE_ID = xx03_if_head_line_rec.HEAD_INTERFACE_ID;
--
    -- �w�b�_�f�[�^�ۑ�
    INSERT INTO XX03_JOURNAL_SLIPS(
      JOURNAL_ID                   ,
      WF_STATUS                    ,
      SLIP_TYPE                    ,
      JOURNAL_NUM                  ,
      ENTRY_DATE                   ,
      REQUEST_KEY                  ,
      REQUESTOR_PERSON_ID          ,
      REQUESTOR_PERSON_NAME        ,
      APPROVER_PERSON_ID           ,
      APPROVER_PERSON_NAME         ,
      REQUEST_DATE                 ,
      APPROVAL_DATE                ,
      REJECTION_DATE               ,
      ACCOUNT_APPROVER_PERSON_ID   ,
      ACCOUNT_APPROVAL_DATE        ,
      GL_FORWORD_DATE              ,
      RECOGNITION_CLASS            ,
      APPROVER_COMMENTS            ,
      REQUEST_ENABLE_FLAG          ,
      ACCOUNT_REVISION_FLAG        ,
      TOTAL_ENTERED_DR             ,
      TOTAL_ACCOUNTED_DR           ,
      TOTAL_ITEM_ENTERED_DR        ,
      TOTAL_TAX_ENTERED_DR         ,
      TOTAL_ENTERED_CR             ,
      TOTAL_ACCOUNTED_CR           ,
      TOTAL_ITEM_ENTERED_CR        ,
      TOTAL_TAX_ENTERED_CR         ,
      INVOICE_CURRENCY_CODE        ,
      EXCHANGE_RATE                ,
      EXCHANGE_RATE_TYPE           ,
      EXCHANGE_RATE_TYPE_NAME      ,
      IGNORE_RATE_FLAG             ,
      DESCRIPTION                  ,
      ENTRY_DEPARTMENT             ,
      ENTRY_PERSON_ID              ,
      ORIG_JOURNAL_NUM             ,
      ACCOUNT_APPROVAL_FLAG        ,
      PERIOD_NAME                  ,
      GL_DATE                      ,
      AUTO_TAX_CALC_FLAG           ,
      AP_TAX_ROUNDING_RULE         ,
      FORM_SELECT_FLAG             ,
      ORG_ID                       ,
      SET_OF_BOOKS_ID              ,
      RECURRING_HEADER_NAME        ,
      ATTRIBUTE_CATEGORY           ,
      ATTRIBUTE1                   ,
      ATTRIBUTE2                   ,
      ATTRIBUTE3                   ,
      ATTRIBUTE4                   ,
      ATTRIBUTE5                   ,
      ATTRIBUTE6                   ,
      ATTRIBUTE7                   ,
      ATTRIBUTE8                   ,
      ATTRIBUTE9                   ,
      ATTRIBUTE10                  ,
      ATTRIBUTE11                  ,
      ATTRIBUTE12                  ,
      ATTRIBUTE13                  ,
      ATTRIBUTE14                  ,
      ATTRIBUTE15                  ,
      CREATED_BY                   ,
      CREATION_DATE                ,
      LAST_UPDATED_BY              ,
      LAST_UPDATE_DATE             ,
      LAST_UPDATE_LOGIN            ,
      REQUEST_ID                   ,
      PROGRAM_APPLICATION_ID       ,
      PROGRAM_UPDATE_DATE          ,
      PROGRAM_ID
    )
    VALUES(
      gn_journal_id,
      xx03_if_head_line_rec.HEAD_WF_STATUS,
      xx03_if_head_line_rec.HEAD_SLIP_TYPE,
      gn_journal_id,
      xx03_if_head_line_rec.HEAD_ENTRY_DATE,
      NULL,
      xx03_if_head_line_rec.HEAD_REQUESTOR_PERSON_ID,
      xx03_if_head_line_rec.HEAD_REQUESTOR_PERSON_NAME,
      xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID,
      xx03_if_head_line_rec.HEAD_APPROVER_PERSON_NAME,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      0,
      NULL,
      'N',
      'N',
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE_NAME,
      xx03_if_head_line_rec.HEAD_IGNORE_RATE_FLAG,
      xx03_if_head_line_rec.HEAD_DESCRIPTION,
      xx03_if_head_line_rec.HEAD_ENTRY_DEPARTMENT,
      xx03_if_head_line_rec.HEAD_ENTRY_PERSON_ID,
      NULL,
      'N',
      xx03_if_head_line_rec.HEAD_PERIOD_NAME,
      xx03_if_head_line_rec.HEAD_GL_DATE,
      xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG,
      xx03_if_head_line_rec.HEAD_AP_TAX_ROUNDING_RULE,
      NULL,
      xx03_if_head_line_rec.HEAD_ORG_ID,
      xx03_if_head_line_rec.HEAD_SET_OF_BOOKS_ID,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      xx00_global_pkg.user_id,
      xx00_date_pkg.get_system_datetime_f,
      xx00_global_pkg.user_id,
      xx00_date_pkg.get_system_datetime_f,
      xx00_global_pkg.login_id,
      xx00_global_pkg.conc_request_id,
      xx00_global_pkg.prog_appl_id,
      xx00_date_pkg.get_system_datetime_f,
      xx00_global_pkg.conc_program_id
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_header_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_detail_data
   * Description      : ���׃f�[�^�̃R�s�[
   ***********************************************************************************/
  PROCEDURE ins_detail_data(
    iv_source        IN  VARCHAR2,     --  1.�\�[�X
    in_request_id    IN  NUMBER,       --  2.�v��ID
    in_line_count_dr IN  NUMBER,       --  3.�ؕ����׍s��
    in_line_count_cr IN  NUMBER,       --  4.�ݕ����׍s��
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_detail_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_line_id        NUMBER;          -- ����ID
    ln_amount_dr      NUMBER;          -- ���z
    ln_amount_cr      NUMBER;          -- ���z
    lv_slip_type_name VARCHAR2(4000);  -- �E�v����
    ln_line_count     NUMBER;          -- ���׍s��
    lv_amount_includes_tax_flag_dr VARCHAR2(1);
    lv_amount_includes_tax_flag_cr VARCHAR2(1);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
--
    -- ����ID�擾
    SELECT XX03_JOURNAL_SLIP_LINES_S.nextval
    INTO   ln_line_id
    FROM   dual;
--
    -- ���z�Z�o
    IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR = cv_yes ) THEN
      -- '����'��'Y'�̎��͋��z��'�{�̋��z+����Ŋz'
      ln_amount_dr :=  xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR
                     + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR;
    ELSIF  ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR = cv_no ) THEN
      -- '����'��'N'�̎��͋��z��'�{�̋��z'
      ln_amount_dr := xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR;
    ELSE
      -- ver 11.5.10.2.2 Chg Start
      ---- ����ȊO�̎��͓��œ��͒l�G���[
      --ln_amount_dr := 0;
      ---- �X�e�[�^�X���G���[��
      --gv_result := cv_result_error;
      ---- �G���[�������Z
      --gn_error_count := gn_error_count + 1;
      --xx00_file_pkg.output(
      --  xx00_message_pkg.get_msg(
      --    'XX03',
      --    'APP-XX03-08027'
      --  )
      --);
      -- ver 11.5.10.2.5B Chg Start
      ---- ����ȊO�̎��͋��z��0�ɂ���
      --ln_amount_dr := 0;
      -- ����ȊO�̎�(���ׂ̓��͂��Ă��Ȃ��ݎؑ�)�͋��z��null�ɂ���
      ln_amount_dr := null;
      -- ver 11.5.10.2.5B Chg End
      -- ver 11.5.10.2.2 Chg End
    END IF;
--
    -- ���z�Z�o
    IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR = cv_yes ) THEN
      -- '����'��'Y'�̎��͋��z��'�{�̋��z+����Ŋz'
      ln_amount_cr :=  xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR
                     + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR;
    ELSIF  ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR = cv_no ) THEN
      -- '����'��'N'�̎��͋��z��'�{�̋��z'
      ln_amount_cr := xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR;
    ELSE
      -- ver 11.5.10.2.2 Chg Start
      ---- ����ȊO�̎��͓��œ��͒l�G���[
      --ln_amount_cr := 0;
      ---- �X�e�[�^�X���G���[��
      --gv_result := cv_result_error;
      ---- �G���[�������Z
      --gn_error_count := gn_error_count + 1;
      --xx00_file_pkg.output(
      --  xx00_message_pkg.get_msg(
      --    'XX03',
      --    'APP-XX03-08027'
      --  )
      --);
      -- ver 11.5.10.2.5B Chg Start
      ---- ����ȊO�̎��͋��z��0�ɂ���
      --ln_amount_cr := 0;
      -- ����ȊO�̎�(���ׂ̓��͂��Ă��Ȃ��ݎؑ�)�͋��z��null�ɂ���
      ln_amount_cr := null;
      -- ver 11.5.10.2.5B Chg End
      -- ver 11.5.10.2.2 Chg End
    END IF;
--
    -- �Ńt���O�̊m��
    IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NULL THEN
      lv_amount_includes_tax_flag_dr := NULL;
    ELSE
      lv_amount_includes_tax_flag_dr := xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR;
    END IF;
    IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NULL THEN
      lv_amount_includes_tax_flag_cr := NULL;
    ELSE
      lv_amount_includes_tax_flag_cr := xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR;
    END IF;
--
    -- ���׍s���̊m��i�ݕ��ؕ����j
    IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NULL THEN
      ln_line_count := in_line_count_dr;
    ELSE
      ln_line_count := in_line_count_cr;
    END IF;
--
    -- ���׃f�[�^�ۑ�
    INSERT INTO XX03_JOURNAL_SLIP_LINES(
      JOURNAL_LINE_ID             ,
      JOURNAL_ID                  ,
      LINE_NUMBER                 ,
      SLIP_LINE_TYPE_DR           ,
      SLIP_LINE_TYPE_NAME_DR      ,
      ENTERED_AMOUNT_DR           ,
      ENTERED_ITEM_AMOUNT_DR      ,
      AMOUNT_INCLUDES_TAX_FLAG_DR ,
      TAX_CODE_DR                 ,
      TAX_NAME_DR                 ,
      ENTERED_TAX_AMOUNT_DR       ,
      ACCOUNTED_AMOUNT_DR         ,
      SLIP_LINE_TYPE_CR           ,
      SLIP_LINE_TYPE_NAME_CR      ,
      ENTERED_AMOUNT_CR           ,
      ENTERED_ITEM_AMOUNT_CR      ,
      AMOUNT_INCLUDES_TAX_FLAG_CR ,
      TAX_CODE_CR                 ,
      TAX_NAME_CR                 ,
      ENTERED_TAX_AMOUNT_CR       ,
      ACCOUNTED_AMOUNT_CR         ,
      DESCRIPTION                 ,
      SEGMENT1                    ,
      SEGMENT2                    ,
      SEGMENT3                    ,
      SEGMENT4                    ,
      SEGMENT5                    ,
      SEGMENT6                    ,
      SEGMENT7                    ,
      SEGMENT8                    ,
      SEGMENT9                    ,
      SEGMENT10                   ,
      SEGMENT11                   ,
      SEGMENT12                   ,
      SEGMENT13                   ,
      SEGMENT14                   ,
      SEGMENT15                   ,
      SEGMENT16                   ,
      SEGMENT17                   ,
      SEGMENT18                   ,
      SEGMENT19                   ,
      SEGMENT20                   ,
      SEGMENT1_NAME               ,
      SEGMENT2_NAME               ,
      SEGMENT3_NAME               ,
      SEGMENT4_NAME               ,
      SEGMENT5_NAME               ,
      SEGMENT6_NAME               ,
      SEGMENT7_NAME               ,
      SEGMENT8_NAME               ,
      INCR_DECR_REASON_CODE       ,
      INCR_DECR_REASON_NAME       ,
      RECON_REFERENCE             ,
      ORG_ID                      ,
      ATTRIBUTE_CATEGORY          ,
      ATTRIBUTE1                  ,
      ATTRIBUTE2                  ,
      ATTRIBUTE3                  ,
      ATTRIBUTE4                  ,
      ATTRIBUTE5                  ,
      ATTRIBUTE6                  ,
      ATTRIBUTE7                  ,
      ATTRIBUTE8                  ,
      ATTRIBUTE9                  ,
      ATTRIBUTE10                 ,
      ATTRIBUTE11                 ,
      ATTRIBUTE12                 ,
      ATTRIBUTE13                 ,
      ATTRIBUTE14                 ,
      ATTRIBUTE15                 ,
      CREATED_BY                  ,
      CREATION_DATE               ,
      LAST_UPDATED_BY             ,
      LAST_UPDATE_DATE            ,
      LAST_UPDATE_LOGIN           ,
      REQUEST_ID                  ,
      PROGRAM_APPLICATION_ID      ,
      PROGRAM_ID                  ,
      PROGRAM_UPDATE_DATE
    )
    VALUES(
      ln_line_id,
      gn_journal_id,
      ln_line_count,
      NULL,
      NULL,
      ln_amount_dr,
      xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR,
      lv_amount_includes_tax_flag_dr,
      xx03_if_head_line_rec.LINE_TAX_CODE_DR,
      xx03_if_head_line_rec.LINE_TAX_NAME_DR,
      xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR,
      xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR,
      NULL,
      NULL,
      ln_amount_cr,
      xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR,
      lv_amount_includes_tax_flag_cr,
      xx03_if_head_line_rec.LINE_TAX_CODE_CR,
      xx03_if_head_line_rec.LINE_TAX_NAME_CR,
      xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR,
      xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR,
      xx03_if_head_line_rec.LINE_DESCRIPTION,
      xx03_if_head_line_rec.LINE_SEGMENT1,
      xx03_if_head_line_rec.LINE_SEGMENT2,
      xx03_if_head_line_rec.LINE_SEGMENT3,
      xx03_if_head_line_rec.LINE_SEGMENT4,
      xx03_if_head_line_rec.LINE_SEGMENT5,
      xx03_if_head_line_rec.LINE_SEGMENT6,
      xx03_if_head_line_rec.LINE_SEGMENT7,
      xx03_if_head_line_rec.LINE_SEGMENT8,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
      xx03_if_head_line_rec.LINE_SEGMENT1_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT2_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT3_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT4_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT5_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT6_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT7_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT8_NAME,
      xx03_if_head_line_rec.LINE_INCR_DECR_REASON_CODE,
      xx03_if_head_line_rec.LINE_INCR_DECR_REASON_NAME,
      xx03_if_head_line_rec.LINE_RECON_REFERENCE,
      xx03_if_head_line_rec.LINE_ORG_ID,
-- == 2016/11/04 V1.1 Modified START ===============================================================
      xx03_if_head_line_rec.HEAD_SET_OF_BOOKS_ID,
--      NULL,
-- == 2016/11/04 V1.1 Modified END   ===============================================================
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
-- == 2016/11/04 V1.1 Modified START ===============================================================
      xx03_if_head_line_rec.LINE_ATTRIBUTE9,
--      NULL,
-- == 2016/11/04 V1.1 Modified END   ===============================================================
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      xx00_global_pkg.user_id,
      xx00_date_pkg.get_system_datetime_f,
      xx00_global_pkg.user_id,
      xx00_date_pkg.get_system_datetime_f,
      xx00_global_pkg.login_id,
      xx00_global_pkg.conc_request_id,
      xx00_global_pkg.prog_appl_id,
      xx00_global_pkg.conc_program_id,
      xx00_date_pkg.get_system_datetime_f
    );
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : check_header_data
   * Description      : �d��`�[�f�[�^�̓��̓`�F�b�N(E-2)
   ***********************************************************************************/
  PROCEDURE check_header_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_header_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
-- Ver11.5.10.1.5B Add Start
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
-- ver 11.5.10.2.10B Del Start
--    -- ���F�ҏ��J�[�\��
---- Ver11.5.10.1.6B Chg Start
----    CURSOR xx03_approve_chk_cur(i_person_id NUMBER)
--    CURSOR xx03_approve_chk_cur(i_person_id NUMBER, i_val_dep VARCHAR2)
---- Ver11.5.10.1.6B Chg End
--    IS
--      SELECT
--        count('x') rec_cnt
--      FROM
--        XX03_APPROVER_PERSON_LOV_V xaplv
--      WHERE
--        xaplv.PERSON_ID = i_person_id
---- Ver11.5.10.1.6B Add Start
--      AND (   xaplv.PROFILE_VAL_DEP = 'ALL'
--           or xaplv.PROFILE_VAL_DEP = i_val_dep)
---- Ver11.5.10.1.6B Add End
--    ;
--    -- ���F�ҏ��J�[�\�����R�[�h�^
--    xx03_approve_chk_rec xx03_approve_chk_cur%ROWTYPE;
-- ver 11.5.10.2.10B Del End
--
-- Ver11.5.10.1.5B Add End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- �`�[��ʃ`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_SLIP_TYPE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_SLIP_TYPE) = '' ) THEN
      -- �`�[���ID����̏ꍇ�͓`�[��ʓ��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08010'
        )
      );
    END IF;
--
    -- ���F�҃`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_APPROVER_PERSON_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_APPROVER_PERSON_NAME) = '' ) THEN
      -- ���F�Җ�����̏ꍇ�͏��F�ғ��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08011'
        )
      );
-- Ver11.5.10.1.5B Add Start
    -- ���F�҃`�F�b�N
    ELSE 
-- ver 11.5.10.2.10B Chg Start
--      -- ���F�Җ������͂���Ă���ꍇ�͏��F�r���[�ɂčă`�F�b�N
---- Ver11.5.10.1.6B Chg Start
----      OPEN xx03_approve_chk_cur(xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID);
--      OPEN xx03_approve_chk_cur(xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID ,xx03_if_head_line_rec.HEAD_SLIP_TYPE_APP);
---- Ver11.5.10.1.6B Chg End
--      FETCH xx03_approve_chk_cur INTO xx03_approve_chk_rec;
----
--      -- �J�E���g�J�[�\���Ȃ̂ł��肦�Ȃ����A�p�^�[���Ƃ��č쐬
--      IF xx03_approve_chk_cur%NOTFOUND THEN
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(xx00_message_pkg.get_msg('XX03','APP-XX03-08011'));
----
--      -- �Ώۃf�[�^���擾�ł��Ȃ������ꍇ
--      ELSIF xx03_approve_chk_rec.rec_cnt = 0 THEN
--        -- �X�e�[�^�X���G���[��
--        gv_result := cv_result_error;
--        -- �G���[�������Z
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(xx00_message_pkg.get_msg('XX03','APP-XX03-08011'));
--      END IF;
----
--      CLOSE xx03_approve_chk_cur;
--
      -- ���F�Җ������͂���Ă���ꍇ�͏��F�r���[����擾�ł��Ă��邩�ă`�F�b�N
      IF ( xx03_if_head_line_rec.APPROVER_PERSON_ID IS NULL
             OR TRIM(xx03_if_head_line_rec.APPROVER_PERSON_ID) = '' ) THEN
        -- ��̏ꍇ�͏��F�ғ��̓G���[�\��
        -- �X�e�[�^�X���G���[��
        gv_result := cv_result_error;
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08011'
          )
        );
      END IF;
-- ver 11.5.10.2.10B Chg End
-- Ver11.5.10.1.5B Add End
    END IF;
--
    -- �v����`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_GL_DATE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_GL_DATE) = '' ) THEN
      -- �v�������̏ꍇ�͌v������̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08015'
        )
      );
    END IF;
--
    -- ��v���ԃ`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_PERIOD_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_PERIOD_NAME) = '' ) THEN
      -- ��v���Ԃ���̏ꍇ�͉�v���ԓ��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08028'
        )
      );
    END IF;
--
    -- �ʉ݃`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE) = '' ) THEN
      -- �ʉ݂���̏ꍇ�͒ʉݓ��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08018'
        )
      );
    END IF;
--
    -- ���[�g�^�C�v�`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE_NAME IS NOT NULL
           AND ( xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE) = '' )) THEN
      -- ���[�g�^�C�v�R�[�h���擾�ł��Ȃ������ꍇ�̓��[�g�^�C�v���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08025'
        )
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN   -- *** ���������ʗ�O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_header_data;
--
--
  /**********************************************************************************
   * Procedure Name   : check_detail_data
   * Description      : �d��`�[���׃f�[�^�̓��̓`�F�b�N(E-2)
   ***********************************************************************************/
  PROCEDURE check_detail_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_detail_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ��Ѓ`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT1 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT1) = '' ) THEN
      -- ��ЃZ�O�����g����̏ꍇ�͉�Г��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14114'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT1')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- ����`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT2 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT2) = '' ) THEN
      -- ����Z�O�����g����̏ꍇ�͕�����̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14115'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT2')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- ����Ȗڃ`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT3 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT3) = '' ) THEN
      -- ����ȖڃZ�O�����g����̏ꍇ�͊���Ȗړ��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14116'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT3')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- �⏕�Ȗڃ`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT4 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT4) = '' ) THEN
      -- �⏕�ȖڃZ�O�����g����̏ꍇ�͕⏕�Ȗړ��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14117'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT4')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- �����`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT5 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT5) = '' ) THEN
      -- �����Z�O�����g����̏ꍇ�͑������̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14118'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT5')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- ���Ƌ敪�`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT6 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT6) = '' ) THEN
      -- ���Ƌ敪�Z�O�����g����̏ꍇ�͎��Ƌ敪���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14119'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT6')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- �v���W�F�N�g�`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT7 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT7) = '' ) THEN
      -- �v���W�F�N�g�Z�O�����g����̏ꍇ�̓v���W�F�N�g���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14120'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT7')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- �\���`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT8 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT8) = '' ) THEN
      -- �\���Z�O�����g����̏ꍇ�͗\�����̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-08023'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT8')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
-- ver 11.5.10.2.10 Add Start
    -- �������R�`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_INCR_DECR_REASON_CODE IS NOT NULL
           AND ( xx03_if_head_line_rec.LINE_INCR_DECR_REASON_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_INCR_DECR_REASON_NAME) = '' )) THEN
      -- �������R�R�[�h���͎��ɖ��̂��擾�ł��Ȃ������ꍇ�͑������R���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08047'
        )
      );
    END IF;
-- ver 11.5.10.2.10 Add End
--
    -- ver 11.5.10.2.2 Add Start
    -- �ؕ��ݕ������͂���ĂȂ��ꍇ
    IF (    xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NULL
        AND xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR  IS NULL
        AND xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR    IS NULL
        AND xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR IS NULL
        AND xx03_if_head_line_rec.LINE_TAX_CODE_DR            IS NULL
        AND xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NULL
        AND xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR  IS NULL
        AND xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR    IS NULL
        AND xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR IS NULL
        AND xx03_if_head_line_rec.LINE_TAX_CODE_CR            IS NULL
        ) THEN
      -- �ؕ��ݕ����ɓ��͂���Ă��Ȃ��ꍇ�̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-11573'
        )
      );
    -- �ؕ��ݕ������͂���Ă���ꍇ
    ELSIF (    (   xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NOT NULL
                OR xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR  IS NOT NULL
                OR xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR    IS NOT NULL
                OR xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR IS NOT NULL
                OR xx03_if_head_line_rec.LINE_TAX_CODE_DR            IS NOT NULL
                )
           AND (   xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NOT NULL
                OR xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR  IS NOT NULL
                OR xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR    IS NOT NULL
                OR xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR IS NOT NULL
                OR xx03_if_head_line_rec.LINE_TAX_CODE_CR            IS NOT NULL
                )
           ) THEN
      -- �ؕ��ݕ����ɓ��͂���Ă���ꍇ�̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-11574'
        )
      );
    ELSE
    -- ver 11.5.10.2.2 Add End
--
    -- ver 11.5.10.2.2 Chg Start
    ---- �ؕ��{�̋��z�����͂���Ă���ꍇ
    --IF ( xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NOT NULL
    --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR) != '' ) THEN
    -- �ؕ������͂���Ă���ꍇ
    IF (   xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NOT NULL
        OR xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR  IS NOT NULL
        OR xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR    IS NOT NULL
        OR xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR IS NOT NULL
        OR xx03_if_head_line_rec.LINE_TAX_CODE_DR            IS NOT NULL
        ) THEN
    -- ver 11.5.10.2.2 Chg End
--
      -- ver 11.5.10.2.2 Add Start
      -- �{�̋��z(DR)�`�F�b�N
      IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NULL THEN
        -- �ؕ��{�̋��z����̏ꍇ�͎ؕ��{�̋��z���̓G���[�\��
        -- �X�e�[�^�X���G���[��
        gv_result := cv_result_error;
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08021'
          )
        );
      END IF;
      -- ver 11.5.10.2.2 Add Start
--
      -- ver 11.5.10.2.2 Chg Start
      -- ����Ŋz(DR)�`�F�b�N
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR IS NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR) = '' ) THEN
      IF xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR IS NULL THEN
      -- ver 11.5.10.2.2 Chg End
        -- �ؕ�����Ŋz����̏ꍇ�͏���Ŋz���̓G���[�\��
        -- �X�e�[�^�X���G���[��
        gv_result := cv_result_error;
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-14113'
          )
        );
      END IF;
--
      -- ����(DR)�`�F�b�N
      IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR IS NULL
             OR TRIM(xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR) = '' ) THEN
        -- �ؕ����ł���̏ꍇ�͓��œ��̓G���[�\��
        -- �X�e�[�^�X���G���[��
        gv_result := cv_result_error;
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08022'
          )
        );
      ELSE
        -- ����(DR)���͒l�`�F�b�N
        IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR != cv_yes
               AND xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR != cv_no ) THEN
          -- �ؕ����ł̓��͒l���s���̏ꍇ�͓��œ��͒l�G���[�\��
          -- �X�e�[�^�X���G���[��
          gv_result := cv_result_error;
          -- �G���[�������Z
          gn_error_count := gn_error_count + 1;
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-08027'
            )
          );
        END IF;
      END IF;
--
      -- �ŋ敪(DR)�`�F�b�N
-- ver 11.5.10.2.10 Chg Start
--      IF ( xx03_if_head_line_rec.LINE_TAX_CODE_DR IS NULL
--             OR TRIM(xx03_if_head_line_rec.LINE_TAX_CODE_DR) = '' ) THEN
      IF ( xx03_if_head_line_rec.LINE_TAX_NAME_DR IS NULL
             OR TRIM(xx03_if_head_line_rec.LINE_TAX_NAME_DR) = '' ) THEN
-- ver 11.5.10.2.10 Chg End
        -- �ؕ��ŋ敪����̏ꍇ�͐ŋ敪���̓G���[�\��
        -- �X�e�[�^�X���G���[��
        gv_result := cv_result_error;
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-14111'
          )
        );
      END IF;
--
      -- ���Z�ϋ��z(DR)�`�F�b�N
      -- ver 11.5.10.2.2 Chg Start
      --IF xx03_if_head_line_rec.HEAD_IGNORE_RATE_FLAG = 'N' THEN
      --  IF ( xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR IS NULL
      --         OR TRIM(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR) = '' ) THEN
        IF xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR IS NULL THEN
      -- ver 11.5.10.2.2 Chg End
          -- �ؕ����Z�ϋ��z����̏ꍇ�͊��Z�ϋ��z���̓G���[�\��
          -- �X�e�[�^�X���G���[��
          gv_result := cv_result_error;
          -- �G���[�������Z
          gn_error_count := gn_error_count + 1;
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-11505'
            )
          );
        END IF;
      -- ver 11.5.10.2.2 Chg Start
      --END IF;
      -- ver 11.5.10.2.2 Chg End
--
      -- ver 11.5.10.2.2 Del Start
      ---- �{�̋��z(CR)�`�F�b�N
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR) != '' ) THEN
      --  -- �ݕ��{�̋��z����łȂ��ꍇ�͑ݕ��{�̋��z���̓G���[�\��
      --  -- �X�e�[�^�X���G���[��
      --  gv_result := cv_result_error;
      --  -- �G���[�������Z
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11507'
      --    )
      --  );
      --END IF;
--
      ---- ����Ŋz(CR)�`�F�b�N
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR) != '' ) THEN
      --  -- �ݕ�����Ŋz����łȂ��ꍇ�͑ݕ�����Ŋz���̓G���[�\��
      --  -- �X�e�[�^�X���G���[��
      --  gv_result := cv_result_error;
      --  -- �G���[�������Z
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11508'
      --    )
      --  );
      --END IF;
--
      ---- �ŋ敪(CR)�`�F�b�N
      --IF ( xx03_if_head_line_rec.LINE_TAX_CODE_CR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_TAX_CODE_CR) != '' ) THEN
      --  -- �ݕ��ŋ敪����łȂ��ꍇ�͑ݕ��ŋ敪���̓G���[�\��
      --  -- �X�e�[�^�X���G���[��
      --  gv_result := cv_result_error;
      --  -- �G���[�������Z
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11510'
      --    )
      --  );
      --END IF;
--
      ---- ���Z�ϋ��z(CR)�`�F�b�N
      --IF ( xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR) != '' ) THEN
      --  -- �ݕ����Z�ϋ��z����łȂ��ꍇ�͑ݕ����Z�ϋ��z���̓G���[�\��
      --  -- �X�e�[�^�X���G���[��
      --  gv_result := cv_result_error;
      --  -- �G���[�������Z
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11511'
      --    )
      --  );
      --END IF;
    -- ver 11.5.10.2.2 Del Start
--
      -- ver 11.5.10.2.2 Add Start
      -- ���z������͎��`�F�b�N
      IF (    xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR    IS NOT NULL
          AND xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NOT NULL
          AND xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR  IS NOT NULL ) THEN
      -- ver 11.5.10.2.2 Add End
-- ver 11.5.10.1.6E Add Start
      -- �@�\�ʉݎ��A���͋��z�{�́{�ŋ��Ɗ��Z�ϋ��z�̈�v�`�F�b�N(DR)
      IF (    (xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE  =  gv_cur_code)
          AND (xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR   !=  xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR
                                                                  + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR  ) ) THEN
        -- ��v���Ă��Ȃ��ꍇ�͑ݕ����Z�ϋ��z���̓G���[�\��
        -- �X�e�[�^�X���G���[��
        gv_result := cv_result_error;
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-11570'
          )
        );
      END IF;
-- ver 11.5.10.1.6E Add End
      -- ver 11.5.10.2.2 Add Start
      END IF;
      -- ver 11.5.10.2.2 Add End
    END IF;
--
    -- ver 11.5.10.2.2 Chg Start
    --IF ( xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NOT NULL
    --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR) != '' ) THEN
    -- �ݕ������͂���Ă���ꍇ
    IF (   xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NOT NULL
        OR xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR  IS NOT NULL
        OR xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR    IS NOT NULL
        OR xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR IS NOT NULL
        OR xx03_if_head_line_rec.LINE_TAX_CODE_CR            IS NOT NULL
        ) THEN
    -- ver 11.5.10.2.2 Chg End
--
      -- ver 11.5.10.2.2 Add Start
      -- �{�̋��z(CR)�`�F�b�N
      IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NULL THEN
        -- �ݕ��{�̋��z����̏ꍇ�͑ݕ��{�̋��z���̓G���[�\��
        -- �X�e�[�^�X���G���[��
        gv_result := cv_result_error;
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08021'
          )
        );
      END IF;
      -- ver 11.5.10.2.2 Add End
--
      -- ver 11.5.10.2.2 Chg Start
      -- ����Ŋz(CR)�`�F�b�N
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR IS NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR) = '' ) THEN
      IF xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR IS NULL THEN
      -- ver 11.5.10.2.2 Chg End
        -- �ݕ�����Ŋz����̏ꍇ�͏���Ŋz���̓G���[�\��
        -- �X�e�[�^�X���G���[��
        gv_result := cv_result_error;
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-14113'
          )
        );
      END IF;
--
      -- ����(CR)�`�F�b�N
      IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR IS NULL
             OR TRIM(xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR) = '' ) THEN
        -- �ݕ����ł���̏ꍇ�͓��œ��̓G���[�\��
        -- �X�e�[�^�X���G���[��
        gv_result := cv_result_error;
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08022'
          )
        );
      ELSE
        -- ����(CR)���͒l�`�F�b�N
        IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR != cv_yes
               AND xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR != cv_no ) THEN
          -- �ݕ����ł̓��͒l���s���̏ꍇ�͓��œ��͒l�G���[�\��
          -- �X�e�[�^�X���G���[��
          gv_result := cv_result_error;
          -- �G���[�������Z
          gn_error_count := gn_error_count + 1;
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-08027'
            )
          );
        END IF;
      END IF;
--
      -- �ŋ敪(CR)�`�F�b�N
-- ver 11.5.10.2.10 Chg Start
--      IF ( xx03_if_head_line_rec.LINE_TAX_CODE_CR IS NULL
--             OR TRIM(xx03_if_head_line_rec.LINE_TAX_CODE_CR) = '' ) THEN
      IF ( xx03_if_head_line_rec.LINE_TAX_NAME_CR IS NULL
             OR TRIM(xx03_if_head_line_rec.LINE_TAX_NAME_CR) = '' ) THEN
-- ver 11.5.10.2.10 Chg End
        -- �ݕ��ŋ敪����̏ꍇ�͐ŋ敪���̓G���[�\��
        -- �X�e�[�^�X���G���[��
        gv_result := cv_result_error;
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-14111'
          )
        );
      END IF;
--
      -- ���Z�ϋ��z(CR)�`�F�b�N
      IF xx03_if_head_line_rec.HEAD_IGNORE_RATE_FLAG = 'N' THEN
        IF ( xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR IS NULL
               OR TRIM(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR) = '' ) THEN
          -- �ݕ����Z�ϋ��z����̏ꍇ�͊��Z�ϋ��z���̓G���[�\��
          -- �X�e�[�^�X���G���[��
          gv_result := cv_result_error;
          -- �G���[�������Z
          gn_error_count := gn_error_count + 1;
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-11505'
            )
          );
        END IF;
      END IF;
--
      -- ver 11.5.10.2.2 Del Start
      ---- �{�̋��z(DR)�`�F�b�N
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR) != '' ) THEN
      --  -- �ؕ��{�̋��z����łȂ��ꍇ�͎ؕ��{�̋��z���̓G���[�\��
      --  -- �X�e�[�^�X���G���[��
      --  gv_result := cv_result_error;
      --  -- �G���[�������Z
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11512'
      --    )
      --  );
      --END IF;
--
      ---- ����Ŋz(DR)�`�F�b�N
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR) != '' ) THEN
      --  -- �ؕ�����Ŋz����łȂ��ꍇ�͎ؕ�����Ŋz���̓G���[�\��
      --  -- �X�e�[�^�X���G���[��
      --  gv_result := cv_result_error;
      --  -- �G���[�������Z
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11513'
      --    )
      --  );
      --END IF;
--
      ---- �ŋ敪(DR)�`�F�b�N
      --IF ( xx03_if_head_line_rec.LINE_TAX_CODE_DR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_TAX_CODE_DR) != '' ) THEN
      --  -- �ؕ��ŋ敪����łȂ��ꍇ�͎ؕ��ŋ敪���̓G���[�\��
      --  -- �X�e�[�^�X���G���[��
      --  gv_result := cv_result_error;
      --  -- �G���[�������Z
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11515'
      --    )
      --  );
      --END IF;
--
      ---- ���Z�ϋ��z(DR)�`�F�b�N
      --IF ( xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR) != '' ) THEN
      --  -- �ؕ����Z�ϋ��z����łȂ��ꍇ�͎ؕ����Z�ϋ��z���̓G���[�\��
      --  -- �X�e�[�^�X���G���[��
      --  gv_result := cv_result_error;
      --  -- �G���[�������Z
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11516'
      --    )
      --  );
      --END IF;
      -- ver 11.5.10.2.2 Del End
--
      -- ver 11.5.10.2.2 Add Start
      -- ���z������͎��`�F�b�N
      IF (    xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR    IS NOT NULL
          AND xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NOT NULL
          AND xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR  IS NOT NULL ) THEN
      -- ver 11.5.10.2.2 Add End
-- ver 11.5.10.1.6E Add Start
      -- �@�\�ʉݎ��A���͋��z�{�́{�ŋ��Ɗ��Z�ϋ��z�̈�v�`�F�b�N(CR)
      IF (    (xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE  =  gv_cur_code)
          AND (xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR   !=  xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR
                                                                  + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR  ) ) THEN
        -- ��v���Ă��Ȃ��ꍇ�͑ݕ����Z�ϋ��z���̓G���[�\��
        -- �X�e�[�^�X���G���[��
        gv_result := cv_result_error;
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-11571'
          )
        );
      END IF;
-- ver 11.5.10.1.6E Add End
      -- ver 11.5.10.2.2 Add Start
      END IF;
      -- ver 11.5.10.2.2 Add End
    END IF;
--
    -- ver 11.5.10.2.2 Add Start
    END IF;
    -- ver 11.5.10.2.2 Add End
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN   -- *** ���������ʗ�O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : check_head_line_new
   * Description      : �������f�[�^�̓��̓`�F�b�N
   ***********************************************************************************/
  PROCEDURE check_head_line_new(
    in_total_item_amount_dr  IN  NUMBER,       --  1.���v�{�̋��z
    in_total_item_amount_cr  IN  NUMBER,       --  1.���v�{�̋��z
    in_total_tax_amount_dr   IN  NUMBER,       --  2.���v�ŋ����z
    in_total_tax_amount_cr   IN  NUMBER,       --  2.���v�ŋ����z
    in_total_acc_amount_dr   IN  NUMBER,       --  3.���v���Z���z
    in_total_acc_amount_cr   IN  NUMBER,       --  3.���v���Z���z
    ov_errbuf                OUT VARCHAR2,     --  �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode               OUT VARCHAR2,     --  ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg                OUT VARCHAR2)     --  ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_head_line_new'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_app_upd VARCHAR2(1);         -- �d�_�Ǘ��t���O
--
    ln_error_cnt NUMBER;            -- �d��`�F�b�N�G���[����
    lv_error_flg VARCHAR2(1);       -- �d��`�F�b�N�G���[�t���O
    lv_error_flg1 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O1
    lv_error_msg1 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W1
    lv_error_flg2 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O2
    lv_error_msg2 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W2
    lv_error_flg3 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O3
    lv_error_msg3 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W3
    lv_error_flg4 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O4
    lv_error_msg4 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W4
    lv_error_flg5 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O5
    lv_error_msg5 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W5
    lv_error_flg6 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O6
    lv_error_msg6 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W6
    lv_error_flg7 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O7
    lv_error_msg7 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W7
    lv_error_flg8 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O8
    lv_error_msg8 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W8
    lv_error_flg9 VARCHAR2(1);      -- �d��`�F�b�N�G���[�t���O9
    lv_error_msg9 VARCHAR2(5000);   -- �d��`�F�b�N�G���[���b�Z�[�W9
    lv_error_flg10 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O10
    lv_error_msg10 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W10
    lv_error_flg11 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O11
    lv_error_msg11 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W11
    lv_error_flg12 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O12
    lv_error_msg12 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W12
    lv_error_flg13 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O13
    lv_error_msg13 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W13
    lv_error_flg14 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O14
    lv_error_msg14 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W14
    lv_error_flg15 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O15
    lv_error_msg15 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W15
    lv_error_flg16 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O16
    lv_error_msg16 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W16
    lv_error_flg17 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O17
    lv_error_msg17 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W17
    lv_error_flg18 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O18
    lv_error_msg18 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W18
    lv_error_flg19 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O19
    lv_error_msg19 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W19
    lv_error_flg20 VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O20
    lv_error_msg20 VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W20
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- �w�b�_���z�X�V
    UPDATE XX03_JOURNAL_SLIPS xjs
    SET    xjs.TOTAL_ITEM_ENTERED_DR = in_total_item_amount_dr
         , xjs.TOTAL_ITEM_ENTERED_CR = in_total_item_amount_cr
         , xjs.TOTAL_TAX_ENTERED_DR  = in_total_tax_amount_dr
         , xjs.TOTAL_TAX_ENTERED_CR  = in_total_tax_amount_cr
         , xjs.TOTAL_ENTERED_DR      = (in_total_item_amount_dr + in_total_tax_amount_dr)
         , xjs.TOTAL_ENTERED_CR      = (in_total_item_amount_cr + in_total_tax_amount_cr)
         , xjs.TOTAL_ACCOUNTED_DR    = in_total_acc_amount_dr
         , xjs.TOTAL_ACCOUNTED_CR    = in_total_acc_amount_cr
    WHERE  xjs.JOURNAL_ID = gn_journal_id
      AND  xjs.ORG_ID     = gn_org_id;
--
-- ver 11.5.10.1.6E Add Start
    -- ���Z�ϋ��z����v���Ă��Ȃ��ꍇ�G���[
    IF (in_total_acc_amount_dr != in_total_acc_amount_cr) THEN
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(xx00_message_pkg.get_msg('XX03','APP-XX03-11527'));
    END IF;
-- ver 11.5.10.1.6E Add End
--
    -- �d�_�Ǘ��`�F�b�N
    xx03_deptinput_gl_check_pkg.set_account_approval_flag(
      gn_journal_id,
      lv_app_upd,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
    IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      -- ���ʂ�����Ȃ�A�w�b�_���R�[�h�̏d�_�Ǘ��t���O���X�V
      UPDATE XX03_JOURNAL_SLIPS xjs
      SET    xjs.ACCOUNT_APPROVAL_FLAG = lv_app_upd
      WHERE  xjs.JOURNAL_ID = gn_journal_id
        AND  xjs.ORG_ID     = gn_org_id;
    ELSE
      -- ���ʂ�����łȂ���΁A�G���[���b�Z�[�W���o��
      -- �X�e�[�^�X�����݂̒l���X�ɏ�ʂ̒l�̎��͏㏑��
      IF ( TO_NUMBER(lv_retcode) > TO_NUMBER(gv_result)  ) THEN
        gv_result := lv_retcode;
      END IF;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14143'
        )
      );
    END IF;
--
    -- �d��`�F�b�N
    xx03_deptinput_gl_check_pkg.check_deptinput_gl(
      gn_journal_id,
      ln_error_cnt,
      lv_error_flg,
      lv_error_flg1,
      lv_error_msg1,
      lv_error_flg2,
      lv_error_msg2,
      lv_error_flg3,
      lv_error_msg3,
      lv_error_flg4,
      lv_error_msg4,
      lv_error_flg5,
      lv_error_msg5,
      lv_error_flg6,
      lv_error_msg6,
      lv_error_flg7,
      lv_error_msg7,
      lv_error_flg8,
      lv_error_msg8,
      lv_error_flg9,
      lv_error_msg9,
      lv_error_flg10,
      lv_error_msg10,
      lv_error_flg11,
      lv_error_msg11,
      lv_error_flg12,
      lv_error_msg12,
      lv_error_flg13,
      lv_error_msg13,
      lv_error_flg14,
      lv_error_msg14,
      lv_error_flg15,
      lv_error_msg15,
      lv_error_flg16,
      lv_error_msg16,
      lv_error_flg17,
      lv_error_msg17,
      lv_error_flg18,
      lv_error_msg18,
      lv_error_flg19,
      lv_error_msg19,
      lv_error_flg20,
      lv_error_msg20,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
    IF ( ln_error_cnt > 0 ) THEN
      -- �X�e�[�^�X�����݂̒l���X�ɏ�ʂ̒l�̎��͏㏑��
      IF ( gv_result = cv_result_normal AND lv_error_flg = cv_dept_warning ) THEN
        gv_result := cv_result_warning;
      ELSIF ( lv_error_flg = cv_dept_error ) THEN
        gv_result := cv_result_error;
      END IF;
      -- �d��G���[�L�莞�́A���݂��镪�S�ăG���[���b�Z�[�W���o��
      IF ( lv_error_flg1 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg1
          )
        );
      END IF;
      IF ( lv_error_flg2 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg2
          )
        );
      END IF;
      IF ( lv_error_flg3 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg3
          )
        );
      END IF;
      IF ( lv_error_flg4 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg4
          )
        );
      END IF;
      IF ( lv_error_flg5 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg5
          )
        );
      END IF;
      IF ( lv_error_flg6 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg6
          )
        );
      END IF;
      IF ( lv_error_flg7 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg7
          )
        );
      END IF;
      IF ( lv_error_flg8 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg8
          )
        );
      END IF;
      IF ( lv_error_flg9 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg9
          )
        );
      END IF;
      IF ( lv_error_flg10 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg10
          )
        );
      END IF;
      IF ( lv_error_flg11 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg11
          )
        );
      END IF;
      IF ( lv_error_flg12 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg12
          )
        );
      END IF;
      IF ( lv_error_flg13 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg13
          )
        );
      END IF;
      IF ( lv_error_flg14 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg14
          )
        );
      END IF;
      IF ( lv_error_flg15 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg15
          )
        );
      END IF;
      IF ( lv_error_flg16 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg16
          )
        );
      END IF;
      IF ( lv_error_flg17 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg17
          )
        );
      END IF;
      IF ( lv_error_flg18 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg18
          )
        );
      END IF;
      IF ( lv_error_flg19 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg19
          )
        );
      END IF;
      IF ( lv_error_flg20 <> cv_dept_normal ) THEN
        -- �G���[�������Z
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg20
          )
        );
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN   -- *** ���������ʗ�O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_head_line_new;
--
  /**********************************************************************************
   * Procedure Name   : copy_if_data
   * Description      : �C���^�[�t�F�[�X�f�[�^�̃R�s�[(E-1)
   ***********************************************************************************/
  PROCEDURE copy_if_data(
    iv_source     IN  VARCHAR2,     -- 1.�\�[�X
    in_request_id IN  NUMBER,       -- 2.�v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'copy_if_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_max_line              NUMBER := xx00_profile_pkg.value('VO_MAX_FETCH_SIZE'); -- �ő喾�׍s��
    lv_max_over_flg          VARCHAR2(1);   -- �ő喾�׍s�I�[�o�[�t���O
    ln_interface_id          NUMBER;        -- INTERFACE_ID
    ln_if_id_back            NUMBER;        -- INTERFACE_ID�O���R�[�h�d���`�F�b�N
    lv_if_id_new_flg         VARCHAR2(1);   -- INTERFACE_ID�ύX�t���O
    lv_first_flg             VARCHAR2(1);   -- �������R�[�h�t���O
    ln_total_item_amount_dr  NUMBER;        -- �{�̋��z���v
    ln_total_item_amount_cr  NUMBER;        -- �{�̋��z���v
    ln_total_tax_amount_dr   NUMBER;        -- �{�̐ŋ����v
    ln_total_tax_amount_cr   NUMBER;        -- �{�̐ŋ����v
    ln_total_acc_amount_dr   NUMBER;        -- ���Z���z���v
    ln_total_acc_amount_cr   NUMBER;        -- ���Z���z���v
    ln_line_count_dr         NUMBER;        -- ���׌����J�E���g
    ln_line_count_cr         NUMBER;        -- ���׌����J�E���g
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �I���OID�̎擾
    gn_org_id := TO_NUMBER(xx00_profile_pkg.value('ORG_ID'));
--
    -- �@�\�ʉ݃R�[�h�擾
    SELECT gsob.currency_code
      INTO gv_cur_code
      FROM gl_sets_of_books gsob
     WHERE gsob.set_of_books_id = xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
--
    -- �X�e�[�^�X������
    gv_result := cv_result_normal;
    ln_interface_id := NULL;
--
--
    -- �������R�[�h�t���O
    lv_first_flg      := '1';
    ln_if_id_back     := -1;
--
    -- �w�b�_���׏��J�[�\���I�[�v��
    OPEN xx03_if_head_line_cur(iv_source, in_request_id, gv_cur_code);
--
    <<xx03_if_loop>>
    LOOP
--
      FETCH xx03_if_head_line_cur INTO xx03_if_head_line_rec;
      IF xx03_if_head_line_cur%NOTFOUND THEN
        -- �Ώۃf�[�^���Ȃ��Ȃ�܂Ń��[�v
        EXIT xx03_if_loop;
      END IF;
--
      IF ln_if_id_back != xx03_if_head_line_rec.HEAD_INTERFACE_ID THEN
--
        IF lv_first_flg = '1' THEN
          lv_first_flg := '0';
        ELSE
--
          -- �G���[�����o����Ă��Ȃ����݈̂ȍ~�̏������s
          IF ( gn_error_count = 0 ) THEN
            -- �w�b�_���׃`�F�b�N���s
            check_head_line_new(
              ln_total_item_amount_dr, --  1.�{�̍��v���z
              ln_total_item_amount_cr, --  1.�{�̍��v���z
              ln_total_tax_amount_dr,  --  2.�ŋ����v���z
              ln_total_tax_amount_cr,  --  2.�ŋ����v���z
              ln_total_acc_amount_dr,  --  3.���Z���z���v
              ln_total_acc_amount_cr,  --  3.���Z���z���v
              lv_errbuf,               --  �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,              --  ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);              --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          END IF;
--
          -- �G���[���Ȃ������ꍇ��'�G���[�Ȃ�'�o��
          IF ( gn_error_count = 0 ) THEN
            xx00_file_pkg.output(
              xx00_message_pkg.get_msg(
                'XX03',
                'APP-XX03-08020'
              )
            );
          END IF;
--
        END IF;
--
        -- �ꎞ�ۑ��ϐ�
        ln_if_id_back    := xx03_if_head_line_rec.HEAD_INTERFACE_ID;
        lv_if_id_new_flg := '1';
--
        -- ���׍ő�s�I�[�o�[�t���O
        lv_max_over_flg := '0';
--
        -- �w�b�_���z������
        ln_total_item_amount_dr := 0;
        ln_total_item_amount_cr := 0;
        ln_total_tax_amount_dr  := 0;
        ln_total_tax_amount_cr  := 0;
        ln_total_acc_amount_dr  := 0;
        ln_total_acc_amount_cr  := 0;
--
        -- ���טA�ԏ�����
        ln_line_count_dr  := 1;
        ln_line_count_cr  := 1;
--
        -- �G���[����������
        gn_error_count := 0;
--
      END IF;
--
      -- INTERFACE_ID����l�w�b�_���Q���ȏ�̎��̓w�b�_�G���[
      IF (xx03_if_head_line_rec.CNT_REC_COUNT > 1) THEN
--
        -- �V�w�b�_�̏ꍇ�̓G���[���o��
        IF lv_if_id_new_flg = '1'  THEN
--
          -- INTERFACE_ID����l�w�b�_���Q���ȏ�
          -- �X�e�[�^�X���G���[��
          gv_result := cv_result_error;
          -- �G���[�������Z
          gn_error_count := gn_error_count + 1;
--
          -- INTERFACE_ID�o��
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-08008',
              'TOK_XX03_INTERFACE_ID',
              xx03_if_head_line_rec.HEAD_INTERFACE_ID
            )
          );
          -- �G���[���o��
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-08006'
            )
          );
        END IF;
--
      -- ���׍ő匏���𒴂��Ă��Ȃ��ꍇ�A�㑱�̏������s��
      ELSIF (lv_max_over_flg = '0') THEN
--
        -- �V�w�b�_�̏ꍇ��INTERFACE_ID�o��
        IF lv_if_id_new_flg = '1' THEN
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-08008',
              'TOK_XX03_INTERFACE_ID',
              xx03_if_head_line_rec.HEAD_INTERFACE_ID
            )
          );
--
          -- �V�w�b�_�̏ꍇ�̓w�b�_�`�F�b�N���s
          check_header_data(
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �G���[�����o����Ă��Ȃ����݈̂ȍ~�̏������s
          IF ( gn_error_count = 0 ) THEN
            -- �w�b�_�e�[�u���֑}��
            ins_header_data(
              iv_source,         -- �\�[�X
              in_request_id,     -- �v��ID
              lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
        END IF;
--
        -- ���ׂ̏ꍇ�͖��׃`�F�b�N���s
        check_detail_data(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �G���[�����o����Ă��Ȃ����݈̂ȍ~�̏������s
        IF ( gn_error_count = 0 ) THEN
          -- ���׃e�[�u���֑}��
          ins_detail_data(
            iv_source,         -- �\�[�X
            in_request_id,     -- �v��ID
            ln_line_count_dr,  -- dr���׍s��
            ln_line_count_cr,  -- cr���׍s��
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ���v���z�Z�o�p�ϐ����Z
        ln_total_item_amount_dr := ln_total_item_amount_dr + nvl(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR ,0);
        ln_total_item_amount_cr := ln_total_item_amount_cr + nvl(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR ,0);
        ln_total_tax_amount_dr  := ln_total_tax_amount_dr  + nvl(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR ,0);
        ln_total_tax_amount_cr  := ln_total_tax_amount_cr  + nvl(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR ,0);
        ln_total_acc_amount_dr  := ln_total_acc_amount_dr  + nvl(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR ,0);
        ln_total_acc_amount_cr  := ln_total_acc_amount_cr  + nvl(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR ,0);
--
        -- ���טA�ԉ��Z
        IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NULL THEN
          ln_line_count_dr := ln_line_count_dr + 1;
        ELSE
          ln_line_count_cr := ln_line_count_cr + 1;
        END IF;
--
        -- ���׍ő�s���`�F�b�N
        IF   ln_line_count_dr > (ln_max_line + 1)
          OR ln_line_count_cr > (ln_max_line + 1) THEN
          lv_max_over_flg := '1';
--
          -- �X�e�[�^�X���G���[��
          gv_result := cv_result_error;
          -- �G���[�������Z
          gn_error_count := gn_error_count + 1;
--
          -- ���׍ő吔�G���[�o��
          xx00_file_pkg.output(
            -- ver 11.5.10.2.5 Chg Start
            --xx00_message_pkg.get_msg(
            --  'XXK',
            --  'APP-XXK-14064',
            --  'TOK_MAX_LINE',
            --  ln_max_line
            --)
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-14162',
              'TOK_MAX_LINE',
              ln_max_line
            )
            -- ver 11.5.10.2.5 Chg End
          );
        END IF;
      END IF;
--
      -- �V�w�b�_�t���O������
      lv_if_id_new_flg := '0';
--
    END LOOP xx03_if_loop;
--
    -- ���R�[�h�������t���O���I�t�̏ꍇ��������
    IF lv_first_flg = '0' THEN
--
      -- �G���[�����o����Ă��Ȃ����݈̂ȍ~�̏������s
      IF ( gn_error_count = 0 ) THEN
        -- �w�b�_���׃`�F�b�N���s
        check_head_line_new(
          ln_total_item_amount_dr, --  1.�{�̍��v���z
          ln_total_item_amount_cr, --  1.�{�̍��v���z
          ln_total_tax_amount_dr,  --  2.�ŋ����v���z
          ln_total_tax_amount_cr,  --  2.�ŋ����v���z
          ln_total_acc_amount_dr,  --  3.���Z���z���v
          ln_total_acc_amount_cr,  --  3.���Z���z���v
          lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      END IF;
--
      -- �G���[���Ȃ������ꍇ��'�G���[�Ȃ�'�o��
      IF ( gn_error_count = 0 ) THEN
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08020'
          )
        );
      END IF;
--
    END IF;
--
    CLOSE xx03_if_head_line_cur;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END copy_if_data;
-- Ver11.5.10.1.5 2005/09/06 Change End
--
  /**********************************************************************************
   * Procedure Name   : update_slip_number
   * Description      : �`�[�ԍ��Ǘ��e�[�u���̍X�V
   ***********************************************************************************/
  PROCEDURE update_slip_number(
    in_add_count    IN  NUMBER,       -- 1.�X�V����
    ov_slip_code    OUT VARCHAR2,     -- 2.�d��`�[�R�[�h
    on_slip_number  OUT NUMBER,       -- 3.�`�[�ԍ�
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;  --�����g�����U�N�V������
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_slip_number'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_slip_code VARCHAR2(10);
    ln_slip_number NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ���݂̓`�[�ԍ��擾
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --SELECT xsn.TEMPORARY_CODE,
    --       xsn.SLIP_NUMBER
    --  INTO lv_slip_code,
    --       ln_slip_number
    --  FROM XX03_SLIP_NUMBERS_V xsn
    -- WHERE xsn.APPLICATION_SHORT_NAME = 'SQLGL'
    --   AND xsn.NUM_TYPE = '0' 
    --FOR UPDATE NOWAIT;
    SELECT xsn.TEMPORARY_CODE,
           xsn.SLIP_NUMBER
      INTO lv_slip_code,
           ln_slip_number
      FROM XX03_SLIP_NUMBERS_V xsn
     WHERE xsn.APPLICATION_SHORT_NAME = 'SQLGL'
       AND xsn.NUM_TYPE = '0' 
       AND xsn.ORG_ID = xx00_profile_pkg.value('ORG_ID')
    FOR UPDATE NOWAIT;
    -- Ver11.5.10.1.6D 2006/01/06 Change End
--
    -- �`�[�ԍ����Z
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --UPDATE XX03_SLIP_NUMBERS xsn
    --   SET xsn.SLIP_NUMBER = ln_slip_number + in_add_count
    -- WHERE xsn.APPLICATION_SHORT_NAME = 'SQLGL'
    --   AND xsn.NUM_TYPE = '0';
    UPDATE XX03_SLIP_NUMBERS xsn
       SET xsn.SLIP_NUMBER = ln_slip_number + in_add_count
     WHERE xsn.APPLICATION_SHORT_NAME = 'SQLGL'
       AND xsn.NUM_TYPE = '0'
       AND xsn.ORG_ID = xx00_profile_pkg.value('ORG_ID');
    -- Ver11.5.10.1.6D 2006/01/06 Change End
--
    -- �߂�l�Z�b�g
    ov_slip_code := lv_slip_code;
    on_slip_number := ln_slip_number;
--
    -- COMMIT
    COMMIT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN   -- *** ���������ʗ�O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_slip_number;
--
  /**********************************************************************************
   * Procedure Name   : out_result
   * Description      : �I������(E-7)
   ***********************************************************************************/
  PROCEDURE out_result(
    iv_source      IN  VARCHAR2,     -- 1.�\�[�X
    in_request_id  IN  NUMBER,       -- 2.�v��ID
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_result'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
-- == V1.2 Added START ===============================================================
    cv_slip_code CONSTANT VARCHAR2(3) := 'TMP';
-- == V1.2 Added END   ===============================================================
--
    -- *** ���[�J���ϐ� ***
    ln_update_count NUMBER;     -- �X�V����
-- == V1.2 Delete START ===============================================================
--    lv_slip_code VARCHAR2(10);  -- �d��`�[�R�[�h
--    ln_slip_number NUMBER;      -- �`�[�ԍ�
-- == V1.2 Delete END   ===============================================================
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �X�V�Ώێ擾�J�[�\��
    CURSOR update_record_cur
    IS
      SELECT xjs.JOURNAL_ID
        FROM XX03_JOURNAL_SLIPS xjs
       WHERE xjs.REQUEST_ID = xx00_global_pkg.conc_request_id
      ORDER BY xjs.JOURNAL_ID;
--
    -- ���O�o�͗p�J�[�\��
    CURSOR outlog_cur(pv_source VARCHAR2,
                        pn_request_id NUMBER)
    IS
      SELECT xjsi.INTERFACE_ID as INTERFACE_ID,
             xjs.JOURNAL_NUM as JOURNAL_NUM
        FROM XX03_JOURNAL_SLIPS_IF xjsi,
             XX03_JOURNAL_SLIPS xjs
       WHERE xjsi.REQUEST_ID = pn_request_id
         AND xjsi.SOURCE = pv_source
         AND xjsi.JOURNAL_ID = xjs.JOURNAL_ID;
--
    -- *** ���[�J���E���R�[�h ***
    -- �X�V�Ώێ擾�J�[�\�����R�[�h�^
    update_record_rec      update_record_cur%ROWTYPE;
    -- ���O�o�͗p�J�[�\�����R�[�h�^
    outlog_rec   outlog_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- �`�F�b�N���ʃX�e�[�^�X���G���[�̎��͈ȍ~�̏������s��Ȃ�
    IF ( gv_result =  cv_result_error ) THEN
      RETURN;
    ELSE
      -- �X�V�����擾
      SELECT COUNT(xjs.JOURNAL_ID)
        INTO ln_update_count
        FROM XX03_JOURNAL_SLIPS xjs
       WHERE xjs.REQUEST_ID = xx00_global_pkg.conc_request_id;
--
-- == V1.2 Delete START ===============================================================
--      -- �`�[�ԍ��擾
--      update_slip_number(
--        ln_update_count,
--        lv_slip_code,
--        ln_slip_number,
--        lv_errbuf,
--        lv_retcode,
--        lv_errmsg);
--      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
--        RAISE global_process_expt;
--      ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
--        RAISE global_process_expt;
--      END IF;
----
-- == V1.2 Delete END   ===============================================================
      -- �X�V�Ώێ擾
      OPEN update_record_cur;
      <<update_record_loop>>
      LOOP
--
        FETCH update_record_cur INTO update_record_rec;
        IF update_record_cur%NOTFOUND THEN
          -- �Ώۃf�[�^���Ȃ��Ȃ�܂Ń��[�v
          EXIT update_record_loop;
        END IF;
--
-- == V1.2 Delete START ===============================================================
--        -- �`�[�ԍ����Z
--        ln_slip_number := ln_slip_number + 1;
----
-- == V1.2 Delete END   ===============================================================
        -- �`�[�ԍ��X�V
        UPDATE XX03_JOURNAL_SLIPS xjs
-- == V1.2 Modified START ===============================================================
--           SET xjs.JOURNAL_NUM = lv_slip_code || TO_CHAR(ln_slip_number)
           SET xjs.JOURNAL_NUM = cv_slip_code || TO_CHAR(xxcfo_slip_number_s1.NEXTVAL)
-- == V1.2 Modified END   ===============================================================
         WHERE xjs.JOURNAL_ID = update_record_rec.JOURNAL_ID;
--
      END LOOP update_record_loop;
      CLOSE update_record_cur;
--
      -- �X�V���O�o��
      OPEN outlog_cur(iv_source, in_request_id);
      <<out_log_loop>>
      LOOP
--
        FETCH outlog_cur INTO outlog_rec;
        IF outlog_cur%NOTFOUND THEN
          -- �Ώۃf�[�^���Ȃ��Ȃ�܂Ń��[�v
          EXIT out_log_loop;
        END IF;
--
        -- ���O�o��
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 
            'APP-XX03-08009', 
            'TOK_XX03_INTERFACE_ID', 
            outlog_rec.INTERFACE_ID,
            'TOK_XX03_INVOICE_NUM',
            outlog_rec.JOURNAL_NUM
          )
        );
--
      END LOOP out_log_loop;
      CLOSE outlog_cur;
--
      -- ver 11.5.10.2.5 Del Start
      ---- �C���^�[�t�F�[�X�e�[�u���f�[�^�폜
      --DELETE FROM XX03_JOURNAL_SLIPS_IF xjsi
      --      WHERE xjsi.REQUEST_ID = in_request_id
      --        AND xjsi.SOURCE = iv_source;
      --
      --DELETE FROM XX03_JOURNAL_SLIP_LINES_IF xjsli
      --      WHERE xjsli.REQUEST_ID = in_request_id
      --        AND xjsli.SOURCE = iv_source;
      -- ver 11.5.10.2.5 Del End
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN   -- *** ���������ʗ�O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_result;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_source     IN  VARCHAR2,     -- 1.�t�@�C����
    in_request_id IN  NUMBER,       -- 2.�v��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �w�b�_���o��
    -- ===============================
    print_header(
      iv_source,     -- 1.�\�[�X
      in_request_id, -- 2.�v��ID
      lv_errbuf,     -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,    -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �ꎞ�\����̃f�[�^�R�s�[ (E-1)
    -- ===============================
    copy_if_data(
      iv_source,         -- �\�[�X
      in_request_id,     -- �v��ID
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���s�o��
    xx00_file_pkg.output(' ');
--
    -- ===============================
    -- �I������ (E-7)
    -- ===============================
    out_result(
      iv_source,         -- �\�[�X
      in_request_id,     -- �v��ID
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �R���J�����g�̏I���X�e�[�^�X���`�F�b�N���ʂ̃X�e�[�^�X��
    lv_retcode := gv_result;
    -- �G���[�̎��̓G���[���b�Z�[�W�Z�b�g
    IF ( lv_retcode = cv_result_error ) THEN
      lv_errbuf := xx00_message_pkg.get_msg('XX03', 'APP-XX03-08007');
      lv_errmsg := xx00_message_pkg.get_msg('XX03', 'APP-XX03-08007');
    END IF;
    ov_retcode := lv_retcode;
    ov_errbuf := lv_errbuf;
    ov_errmsg := lv_errmsg;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    WHEN global_process_expt THEN  -- *** ���������ʗ�O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  --*** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_source     IN  VARCHAR2,      -- 1.�\�[�X
    in_request_id IN  NUMBER)        -- 2.�v��ID
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
    -- ===============================
    -- ���O�w�b�_�̏o��
    -- ===============================
    xx00_file_pkg.log_header;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_source,     -- 1.�\�[�X
      in_request_id, -- 2.�v��ID
      lv_errbuf,     -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,    -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xx00_message_pkg.get_msg('XX00','APP-XX00-00001');
      ELSIF (lv_errbuf IS NULL) THEN
        --���[�U�[�E�G���[�E���b�Z�[�W�̃R�s�[
        lv_errbuf := lv_errmsg;
      END IF;
      xx00_file_pkg.log(lv_errbuf);
      xx00_file_pkg.output(lv_errmsg);
    END IF;
    -- ===============================
    -- ���O�t�b�^�̏o��
    -- ===============================
    xx00_file_pkg.log_footer;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    retcode := lv_retcode;
--
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = xx00_common_pkg.set_status_error_f) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    WHEN xx00_global_pkg.global_api_others_expt THEN     -- *** ���ʊ֐�OTHERS��O�n���h�� ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN                              -- *** OTHERS��O�n���h�� ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XX034DD002C;
/
