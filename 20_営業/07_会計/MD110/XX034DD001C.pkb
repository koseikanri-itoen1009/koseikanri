CREATE OR REPLACE PACKAGE BODY XX034DD001C
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : XX034DD001C(body)
 * Description      : �C���^�[�t�F�[�X�e�[�u������̐������f�[�^�C���|�[�g
 * MD.050(CMD.040)  : ������̓o�b�`�����iAP�j OCSJ/BFAFIN/MD050/F212
 * MD.070(CMD.050)  : ������́iAP�j�f�[�^�C���|�[�g OCSJ/BFAFIN/MD070/F423
 * Version          : 11.5.10.2.11
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
 *  2004/04/23   1.0            �V�K�쐬
 *  2004/04/28   1.1            �P�̃e�X�g���{���ʂɂ��C��
 *  2005/02/17   1.2            ���������̒ǉ��yORG_ID�z
 *  2005/04/05   11.5.10.1.0    DELETE_FLAG�X�V
 *  2005/09/05   11.5.10.1.5    �p�t�H�[�}���X���P�Ή�
 *  2005/10/19   11.5.10.1.5B   ���F�҃r���[�Ƃ̌����s��Ή�
 *  2005/12/15   11.5.10.1.6    �ŋ��R�[�h�̗L���`�F�b�N�Ή�
 *                              �w�b�_���׏��J�[�\���ɂĐŋ敪�擾����
 *                              ���������t�ɂ����ėL���Ȑŋ敪���擾����悤�ɕύX
 *  2005/12/19   11.5.10.1.6B   ���F�҂̔��f��̏C���Ή�
 *  2005/12/28   11.5.10.1.6C   �`�[��ʂɃA�v���P�[�V�������̍i���݂�ǉ�
 *  2006/01/06   11.5.10.1.6D   �`�[�ԍ��̍̔ԏ����ɃI���O��ǉ�
 *  2006/01/20   11.5.10.1.6E   11.5.10.1.5�ł̏C���s��ďC��
 *  2006/03/03   11.5.10.1.6F   �e�^�C�~���O�ňقȂ�}�X�^�`�F�b�N�𓯂��ɂ���
 *  2006/09/05   11.5.10.2.5    �A�b�v���[�h�����ŕ������[�U�̓������s�\�Ƃ���
 *                              ����̌��A�f�[�^�폜�����̌��C��
 *                              ���b�Z�[�W�R�[�h�̌��C��
 *  2006/09/20   11.5.10.2.5B   �������s���\�Ƃ���Ή��̍ďC��
 *  2006/10/03   11.5.10.2.6    �}�X�^�`�F�b�N�̌�����(�L�����̃`�F�b�N�𐿋������t��
 *                              �s�Ȃ����ڂ�SYSDATE�ōs�Ȃ����ڂ��Ċm�F)
 *  2007/02/23   11.5.10.2.7    �v���O�������s���̃��[�U�E�E�ӂɕR�t�����j���[��
 *                              �o�^����Ă���`�[��ʂ��̃`�F�b�N��ǉ�
 *  2007/07/17   11.5.10.2.10   �}�X�^�`�F�b�N�̒ǉ�(���ׁF�������R)
 *  2007/08/10   11.5.10.2.10B  �E�v�R�[�h���̎擾��SQL������Ă��邱�Ƃ̏C��
 *  2007/08/16   11.5.10.2.10C  ��s�x�X/��s�����̖������͑O���܂ŗL���Ƃ���悤�ɏC��
 *  2007/10/04   11.5.10.2.10D  �U��������`�F�b�N���Ɏx�����@���d�M���ǂ����Ƃ���
 *                              ���f���s���Ă��邪�A�d����T�C�g�̎x�����@�ł͂Ȃ�
 *                              �x���O���[�v��DFF�x�����@���g�p����悤�ɏC��
 *  2007/10/10   11.5.10.2.10E  �p�t�H�[�}���X�Ή��̂��ߏ��F�҂̃`�F�b�NSQL��
 *                              ���C��SQL�֑g�ݍ��ނ悤�ɏC��
 *  2007/10/17   11.5.10.2.10F  11.5.10.2.10E�ɂđg�ݍ���SQL�Ŏg�p���Ă���
 *                              ���W���[���R�[�h�̌����C��
 *  2007/10/29   11.5.10.2.10G  �ʉ݂̐��x�`�F�b�N(���͉\���x�����`�F�b�N)�ǉ��̂���
 *                              �`�[���擾���ɒʉݏ����Ɋۂ߂鏈�����폜
 *  2016/11/11   11.5.10.2.10H  [E_�{�ғ�_13901]�Ή� �g�c���ϔԍ��̒ǉ�
 *  2020/02/02   11.5.10.2.10I  ��Q�Ή�E_�{�ғ�_16026
 *  2021/12/20   11.5.10.2.11   [E_�{�ғ�_17678]�Ή� �d�q����ۑ��@�����Ή�
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
  cv_appli_cd        CONSTANT VARCHAR2(30)  := 'GL';            -- �A�v���P�[�V�������2
  cv_package_name    CONSTANT VARCHAR2(20)  := 'XX034DD001';    -- �p�b�P�[�W��
  cv_yes             CONSTANT VARCHAR2(1)   := 'Y';             -- �͂�
  cv_no              CONSTANT VARCHAR2(1)   := 'N';             -- ������
  cv_dept_normal     CONSTANT VARCHAR2(1)   := 'S';             -- �d��`�F�b�N���ʁi����j
  cv_dept_warning    CONSTANT VARCHAR2(1)   := 'W';             -- �d��`�F�b�N���ʁi�x���j
  cv_dept_error      CONSTANT VARCHAR2(1)   := 'E';             -- �d��`�F�b�N���ʁi�G���[�j
  cv_result_normal   CONSTANT VARCHAR2(1)   := '0';             -- �I���X�e�[�^�X�i����j
  cv_result_warning  CONSTANT VARCHAR2(1)   := '1';             -- �I���X�e�[�^�X�i�x���j
  cv_result_error    CONSTANT VARCHAR2(1)   := '2';             -- �I���X�e�[�^�X�i�G���[�j
  -- ver 11.5.10.2.6 Add Start
  cv_paymethod_eft   CONSTANT VARCHAR2(3)   := 'EFT';           -- �d����T�C�g�x�����@��d�M�('EFT')
  -- ver 11.5.10.2.6 Add End
--
  -- ver 11.5.10.2.7 Add Start
  cv_menu_url_inp   CONSTANT VARCHAR2(100) := 'OA.jsp?page=/oracle/apps/xx03/ap/webui/XX03ApInvoiceInputPG';
  -- ver 11.5.10.2.7 Add End
--
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gn_invoice_id  NUMBER;              -- ������ID
  gn_error_count NUMBER;              -- �G���[����
  gv_result      VARCHAR2(1);         -- �`�F�b�N���ʃX�e�[�^�X
--
-- 20050217 V1.2 START
  gn_org_id      NUMBER;              -- �I���OID
-- 20050217 V1.2 END
-- Ver11.5.10.1.5 2005/09/05 Add Start
  gv_cur_code    VARCHAR2(15);        -- �@�\�ʉ݃R�[�h
-- Ver11.5.10.1.5 2005/09/05 Add End
--
  -- ===============================
  -- �O���[�o���J�[�\��
  -- ===============================
--
-- Ver11.5.10.1.5 2005/09/05 Delete Start
--  -- �w�b�_���J�[�\��
--  CURSOR xx03_if_header_cur(h_source VARCHAR2,
--                             h_request_id NUMBER)
--  IS
--    SELECT
--      xpsi.INTERFACE_ID as INTERFACE_ID,                        -- �C���^�[�t�F�[�XID
--      xpsi.WF_STATUS as WF_STATUS,                              -- �X�e�[�^�X
--      xstl.LOOKUP_CODE as SLIP_TYPE,                            -- �`�[���
--      TRUNC(xpsi.ENTRY_DATE, 'DD') as ENTRY_DATE,               -- �N�[��
--      xpp.PERSON_ID as REQUESTOR_PERSON_ID,                     -- �\����
--      xpp.EMPLOYEE_DISP as REQUESTOR_PERSON_NAME,               -- �\���Җ�
--      xapl.PERSON_ID as APPROVER_PERSON_ID,                     -- ���F��
--      xapl.EMPLOYEE_DISP as APPROVER_PERSON_NAME,               -- ���F�Җ�
--      xpsi.INVOICE_DATE as INVOICE_DATE,                        -- ���������t
--      xvl.VENDOR_ID as VENDOR_ID,                               -- �d����ID
--      xvl.VENDORS_COL as VENDOR_NAME,                           -- �d���於
--      xvsl.VENDOR_SITE_ID as VENDOR_SITE_ID,                    -- �d����T�C�gID
--      xpsi.VENDOR_SITE_CODE as VENDOR_SITE_NAME,                -- �d����T�C�g��
--      xpsi.INVOICE_CURRENCY_CODE as INVOICE_CURRENCY_CODE,      -- �ʉ�
--      xpsi.EXCHANGE_RATE as EXCHANGE_RATE,                      -- ���[�g
--      xct.CONVERSION_TYPE as EXCHANGE_RATE_TYPE,                -- ���[�g�^�C�v
--      xpsi.EXCHANGE_RATE_TYPE_NAME as EXCHANGE_RATE_TYPE_NAME,  -- ���[�g�^�C�v��
--      xatl.TERM_ID as TERMS_ID,                                 -- �x������ID
--      xpsi.TERMS_NAME as TERMS_NAME,                            -- �x��������
--      xpsi.DESCRIPTION as DESCRIPTION,                          -- ���l
--      xpsi.VENDOR_INVOICE_NUM as VENDOR_INVOICE_NUM,            -- �d���搿�����ԍ�
--      xpp.ATTRIBUTE28 as ENTRY_DEPARTMENT,                      -- �N�[����
--      xpp2.PERSON_ID as ENTRY_PERSON_ID,                        -- �`�[���͎�
--      xapgl.LOOKUP_CODE as PAY_GROUP_LOOKUP_CODE,               -- �x���O���[�v
--      xpsi.PAY_GROUP_LOOKUP_NAME as PAY_GROUP_LOOKUP_NAME,      -- �x���O���[�v��
--      xpsi.GL_DATE as GL_DATE,                                  -- �v���
--      xvsl.AUTO_TAX_CALC_FLAG as AUTO_TAX_CALC_FLAG,            -- ����Ōv�Z���x��
--      xvsl.AP_TAX_ROUNDING_RULE as AP_TAX_ROUNDING_RULE,        -- ����Œ[������
--      xpsi.PREPAY_NUM as PREPAY_NUM,                            -- �O�����[���`�[�ԍ�
--      xpsi.TERMS_DATE as TERMS_DATE,                            -- �x���\���
--      xatl.ATTRIBUTE1 as TERMS_CHANGE_FLG,                      -- �x���\����ύX��
--      xpsi.ORG_ID as ORG_ID,                                    -- �I���OID
--      xpsi.CREATED_BY as CREATED_BY,
--      xpsi.CREATION_DATE as CREATION_DATE,
--      xpsi.LAST_UPDATED_BY as LAST_UPDATED_BY,
--      xpsi.LAST_UPDATE_DATE as LAST_UPDATE_DATE,
--      xpsi.LAST_UPDATE_LOGIN as LAST_UPDATE_LOGIN,
--      xpsi.REQUEST_ID as REQUEST_ID,
--      xpsi.PROGRAM_APPLICATION_ID as PROGRAM_APPLICATION_ID,
--      xpsi.PROGRAM_ID as PROGRAM_ID,
--      xpsi.PROGRAM_UPDATE_DATE as PROGRAM_UPDATE_DATE
--     FROM
--      XX03_PAYMENT_SLIPS_IF xpsi,
--      XX03_SLIP_TYPES_LOV_V xstl,
--      XX03_PER_PEOPLES_V xpp,
--      XX03_PER_PEOPLES_V xpp2,
--      XX03_APPROVER_PERSON_LOV_V xapl,
--      XX03_VENDORS_LOV_V xvl,
--      XX03_VENDOR_SITES_LOV_V xvsl,
--      XX03_CONVERSION_TYPES_V xct,
--      XX03_AP_TERMS_LOV_V xatl,
--      XX03_AP_PAY_GROUPS_LOV_V xapgl
--     WHERE
--      xpsi.REQUEST_ID = h_request_id
--      AND xpsi.SOURCE = h_source
--      AND xpsi.SLIP_TYPE_NAME = xstl.DESCRIPTION (+)
--      AND xpsi.REQUESTOR_PERSON_NUMBER = xpp.EMPLOYEE_NUMBER (+)
--      AND xpsi.ENTRY_PERSON_NUMBER = xpp2.EMPLOYEE_NUMBER (+)
--      AND xpsi.APPROVER_PERSON_NUMBER = xapl.EMPLOYEE_NUMBER (+)
--      AND xpsi.VENDOR_CODE = xvl.SEGMENT1 (+)
--      AND xpsi.VENDOR_CODE = xvsl.VENDOR_NUMBER (+)
--      AND xpsi.VENDOR_SITE_CODE = xvsl.VENDOR_SITE_CODE (+)
--      AND xpsi.EXCHANGE_RATE_TYPE_NAME = xct.USER_CONVERSION_TYPE (+)
--      AND xpsi.TERMS_NAME = xatl.NAME (+)
--      AND xpsi.PAY_GROUP_LOOKUP_NAME = xapgl.MEANING (+)
--     ORDER BY
--      xpsi.INTERFACE_ID;
----
--  --  �w�b�_���J�[�\�����R�[�h�^
--  xx03_if_header_rec    xx03_if_header_cur%ROWTYPE;
----
-- Ver11.5.10.1.5 2005/09/05 Delete End
--
-- Ver11.5.10.1.5 2005/09/05 Add Start
  -- �w�b�_���׏��J�[�\��
  CURSOR xx03_if_head_line_cur( h_source     VARCHAR2
                               ,h_request_id NUMBER)
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
     , HEAD.INVOICE_DATE           as HEAD_INVOICE_DATE                  -- ���������t
     , HEAD.VENDOR_ID              as HEAD_VENDOR_ID                     -- �d����ID
     , HEAD.VENDOR_NAME            as HEAD_VENDOR_NAME                   -- �d���於
     , HEAD.VENDOR_SITE_ID         as HEAD_VENDOR_SITE_ID                -- �d����T�C�gID
     , HEAD.VENDOR_SITE_NAME       as HEAD_VENDOR_SITE_NAME              -- �d����T�C�g��
     -- ver 11.5.10.2.6 Add Start
     -- ver 11.5.10.2.10D Del Start
     --, HEAD.VENDOR_PAYMETHOD       as HEAD_VENDOR_PAYMETHOD              -- �d����T�C�g�x�����@
     -- ver 11.5.10.2.10D Del End
     , HEAD.VENDOR_BANK_NAME       as HEAD_VENDOR_BANK_NAME              -- �d����T�C�g�U���������
     -- ver 11.5.10.2.6 Add End
     , HEAD.INVOICE_CURRENCY_CODE  as HEAD_INVOICE_CURRENCY_CODE         -- �ʉ�
     , HEAD.EXCHANGE_RATE          as HEAD_EXCHANGE_RATE                 -- ���[�g
     , HEAD.EXCHANGE_RATE_TYPE     as HEAD_EXCHANGE_RATE_TYPE            -- ���[�g�^�C�v
     , HEAD.EXCHANGE_RATE_TYPE_NAME  as HEAD_EXCHANGE_RATE_TYPE_NAME     -- ���[�g�^�C�v��
     , HEAD.TERMS_ID               as HEAD_TERMS_ID                      -- �x������ID
     , HEAD.TERMS_NAME             as HEAD_TERMS_NAME                    -- �x��������
     , HEAD.DESCRIPTION            as HEAD_DESCRIPTION                   -- ���l
     , HEAD.VENDOR_INVOICE_NUM     as HEAD_VENDOR_INVOICE_NUM            -- �d���搿�����ԍ�
     , HEAD.ENTRY_DEPARTMENT       as HEAD_ENTRY_DEPARTMENT              -- �N�[����
     , HEAD.ENTRY_PERSON_ID        as HEAD_ENTRY_PERSON_ID               -- �`�[���͎�
     , HEAD.PAY_GROUP_LOOKUP_CODE  as HEAD_PAY_GROUP_LOOKUP_CODE         -- �x���O���[�v
     , HEAD.PAY_GROUP_LOOKUP_NAME  as HEAD_PAY_GROUP_LOOKUP_NAME         -- �x���O���[�v��
     -- ver 11.5.10.2.10D Add Start
     , HEAD.PAY_GROUP_PAYMETHOD    as HEAD_PAY_GROUP_PAYMETHOD           -- �x���O���[�vDFF�x�����@
     -- ver 11.5.10.2.10D Add End
     , HEAD.GL_DATE                as HEAD_GL_DATE                       -- �v���
     , HEAD.AUTO_TAX_CALC_FLAG     as HEAD_AUTO_TAX_CALC_FLAG            -- ����Ōv�Z���x��
     , HEAD.AP_TAX_ROUNDING_RULE   as HEAD_AP_TAX_ROUNDING_RULE          -- ����Œ[������
     , HEAD.PREPAY_NUM             as HEAD_PREPAY_NUM                    -- �O�����[���`�[�ԍ�
     , HEAD.PREPAY_INVOICE_NUM     as HEAD_PREPAY_INVOICE_NUM            --
     , HEAD.PREPAY_AMOUNT_APPLIED  as HEAD_PREPAY_AMOUNT_APPLIED         --
     , HEAD.TERMS_DATE             as HEAD_TERMS_DATE                    -- �x���\���
     , HEAD.TERMS_CHANGE_FLG       as HEAD_TERMS_CHANGE_FLG              -- �x���\����ύX��
     , HEAD.ORG_ID                 as HEAD_ORG_ID                        -- �I���OID
     -- ver 11.5.10.2.11 Add Start
     , HEAD.INVOICE_ELE_DATA_YES   as HEAD_INVOICE_ELE_DATA_YES          -- �������d�q�f�[�^��̂���
     , HEAD.INVOICE_ELE_DATA_NO    as HEAD_INVOICE_ELE_DATA_NO           -- �������d�q�f�[�^��̂Ȃ�
     -- ver 11.5.10.2.11 Add End
     , HEAD.CREATED_BY             as HEAD_CREATED_BY                    --
     , HEAD.CREATION_DATE          as HEAD_CREATION_DATE                 --
     , HEAD.LAST_UPDATED_BY        as HEAD_LAST_UPDATED_BY               --
     , HEAD.LAST_UPDATE_DATE       as HEAD_LAST_UPDATE_DATE              --
     , HEAD.LAST_UPDATE_LOGIN      as HEAD_LAST_UPDATE_LOGIN             --
     , HEAD.REQUEST_ID             as HEAD_REQUEST_ID                    --
     , HEAD.PROGRAM_APPLICATION_ID as HEAD_PROGRAM_APPLICATION_ID        --
     , HEAD.PROGRAM_ID             as HEAD_PROGRAM_ID                    --
     , HEAD.PROGRAM_UPDATE_DATE    as HEAD_PROGRAM_UPDATE_DATE           --
     , LINE.INTERFACE_ID           as LINE_INTERFACE_ID                  -- �C���^�[�t�F�[�XID
     , LINE.LINE_NUMBER            as LINE_LINE_NUMBER                   -- ���C���i���o�[
     , LINE.SLIP_LINE_TYPE         as LINE_SLIP_LINE_TYPE                -- �E�v�R�[�h
     -- ver 11.5.10.1.6F Add Start
     , LINE.SLIP_LINE_TYPE_NAME    as LINE_SLIP_LINE_TYPE_NAME           -- �E�v�R�[�h����
     -- ver 11.5.10.1.6F Add Start
     -- ver 11.5.10.2.10G Chg Start
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_ITEM_AMOUNT
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_ITEM_AMOUNT           -- �{�̋��z
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_TAX_AMOUNT
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_TAX_AMOUNT            -- ����Ŋz
     , LINE.ENTERED_ITEM_AMOUNT    as LINE_ENTERED_ITEM_AMOUNT           -- �{�̋��z
     , LINE.ENTERED_TAX_AMOUNT     as LINE_ENTERED_TAX_AMOUNT            -- ����Ŋz
     -- ver 11.5.10.2.10G Chg Start
     , LINE.DESCRIPTION            as LINE_DESCRIPTION                   -- ���l
     , LINE.AMOUNT_INCLUDES_TAX_FLAG  as LINE_AMOUNT_INCLUDES_TAX_FLAG   -- ����
     , LINE.TAX_CODE               as LINE_TAX_CODE                      -- �ŋ敪
     , LINE.TAX_NAME               as LINE_TAX_NAME                      -- �ŋ敪��
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
-- ver 11.5.10.2.10H Add Start
     , LINE.ATTRIBUTE7             as LINE_ATTRIBUTE7                    -- �g�c���ϔԍ�
-- ver 11.5.10.2.10H Add End
     , LINE.CREATED_BY             as LINE_CREATED_BY                    --
     , LINE.CREATION_DATE          as LINE_CREATION_DATE                 --
     , LINE.LAST_UPDATED_BY        as LINE_LAST_UPDATED_BY               --
     , LINE.LAST_UPDATE_DATE       as LINE_LAST_UPDATE_DATE              --
     , LINE.LAST_UPDATE_LOGIN      as LINE_LAST_UPDATE_LOGIN             --
     , LINE.REQUEST_ID             as LINE_REQUEST_ID                    --
     , LINE.PROGRAM_APPLICATION_ID as LINE_PROGRAM_APPLICATION_ID        --
     , LINE.PROGRAM_ID             as LINE_PROGRAM_ID                    --
     , LINE.PROGRAM_UPDATE_DATE    as LINE_PROGRAM_UPDATE_DATE           --
     , CNT.INTERFACE_ID            as CNT_INTERFACE_ID                   -- �C���^�[�t�F�[�XID
     , CNT.REC_COUNT               as CNT_REC_COUNT                      --
     -- ver 11.5.10.2.10E Add Start
     , APPROVER.PERSON_ID          as APPROVER_PERSON_ID
     -- ver 11.5.10.2.10E Add End
    FROM
       (SELECT /*+ USE_NL(xpsi) */
           xpsi.INTERFACE_ID           as INTERFACE_ID                       -- �C���^�[�t�F�[�XID
         , xpsi.WF_STATUS              as WF_STATUS                          -- �X�e�[�^�X
         , xstl.LOOKUP_CODE            as SLIP_TYPE                          -- �`�[���
-- Ver11.5.10.1.6B Add Start
         , xstl.ATTRIBUTE14            as SLIP_TYPE_APP                      -- �`�[��ʃA�v���P�[�V����
-- Ver11.5.10.1.6B Add End
         , TRUNC(xpsi.ENTRY_DATE, 'DD')  as ENTRY_DATE                       -- �N�[��
         , xpp.PERSON_ID               as REQUESTOR_PERSON_ID                -- �\����
         , xpp.EMPLOYEE_DISP           as REQUESTOR_PERSON_NAME              -- �\���Җ�
-- Ver11.5.10.1.5B Chg Start
         --, xapl.PERSON_ID              as APPROVER_PERSON_ID                 -- ���F��
         --, xapl.EMPLOYEE_DISP          as APPROVER_PERSON_NAME               -- ���F�Җ�
         , ppf.person_id               as APPROVER_PERSON_ID                 -- ���F��
         , ppf.EMPLOYEE_NUMBER ||
           XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') ||
           ppf.PER_INFORMATION18 || ' ' ||
           ppf.PER_INFORMATION19       as APPROVER_PERSON_NAME               -- ���F�Җ�
-- Ver11.5.10.1.5B Chg End
         , xpsi.INVOICE_DATE           as INVOICE_DATE                       -- ���������t
         , xvl.VENDOR_ID               as VENDOR_ID                          -- �d����ID
         , xvl.VENDORS_COL             as VENDOR_NAME                        -- �d���於
         , xvsl.VENDOR_SITE_ID         as VENDOR_SITE_ID                     -- �d����T�C�gID
         , xvsl.VENDOR_SITE_CODE       as VENDOR_SITE_NAME                   -- �d����T�C�g��
         -- ver 11.5.10.2.6 Add Start
         -- ver 11.5.10.2.10D Del Start
         --, xvsl.PAYMETHOD              as VENDOR_PAYMETHOD                   -- �d����T�C�g�x�����@
         -- ver 11.5.10.2.10D Del End
         , xvsl.BANK_NAME              as VENDOR_BANK_NAME                   -- �d����T�C�g�U���������
         -- ver 11.5.10.2.6 Add Start
         , xpsi.INVOICE_CURRENCY_CODE  as INVOICE_CURRENCY_CODE              -- �ʉ�
         , xpsi.EXCHANGE_RATE          as EXCHANGE_RATE                      -- ���[�g
         , xct.CONVERSION_TYPE         as EXCHANGE_RATE_TYPE                 -- ���[�g�^�C�v
         , xpsi.EXCHANGE_RATE_TYPE_NAME  as EXCHANGE_RATE_TYPE_NAME          -- ���[�g�^�C�v��
         , xatl.TERM_ID                as TERMS_ID                           -- �x������ID
         , xpsi.TERMS_NAME             as TERMS_NAME                         -- �x��������
         , xpsi.DESCRIPTION            as DESCRIPTION                        -- ���l
         , xpsi.VENDOR_INVOICE_NUM     as VENDOR_INVOICE_NUM                 -- �d���搿�����ԍ�
         , xpp.ATTRIBUTE28             as ENTRY_DEPARTMENT                   -- �N�[����
         , xpp2.PERSON_ID              as ENTRY_PERSON_ID                    -- �`�[���͎�
         , xapgl.LOOKUP_CODE           as PAY_GROUP_LOOKUP_CODE              -- �x���O���[�v
         , xpsi.PAY_GROUP_LOOKUP_NAME  as PAY_GROUP_LOOKUP_NAME              -- �x���O���[�v��
         -- ver 11.5.10.2.10D Add Start
         , xapgl.ATTRIBUTE1            as PAY_GROUP_PAYMETHOD                -- �x���O���[�vDFF�x�����@
         -- ver 11.5.10.2.10D Add End
         , xpsi.GL_DATE                as GL_DATE                            -- �v���
         , xvsl.AUTO_TAX_CALC_FLAG     as AUTO_TAX_CALC_FLAG                 -- ����Ōv�Z���x��
         , xvsl.AP_TAX_ROUNDING_RULE   as AP_TAX_ROUNDING_RULE               -- ����Œ[������
         , xpsi.PREPAY_NUM             as PREPAY_NUM                         -- �O�����[���`�[�ԍ�
         , xpl.INVOICE_NUM             as PREPAY_INVOICE_NUM                 --
         , xpl.PREPAY_AMOUNT_APPLIED   as PREPAY_AMOUNT_APPLIED              --
         , xpsi.TERMS_DATE             as TERMS_DATE                         -- �x���\���
         , xatl.ATTRIBUTE1             as TERMS_CHANGE_FLG                   -- �x���\����ύX��
         , xpsi.ORG_ID                 as ORG_ID                             -- �I���OID
-- ver 11.5.10.2.11 Add Start
         , xpsi.INVOICE_ELE_DATA_YES   as INVOICE_ELE_DATA_YES               -- �������d�q�f�[�^��̂���
         , xpsi.INVOICE_ELE_DATA_NO    as INVOICE_ELE_DATA_NO                -- �������d�q�f�[�^��̂Ȃ�
-- ver 11.5.10.2.11 Add End
         , xpsi.CREATED_BY             as CREATED_BY                         --
         , xpsi.CREATION_DATE          as CREATION_DATE                      --
         , xpsi.LAST_UPDATED_BY        as LAST_UPDATED_BY                    --
         , xpsi.LAST_UPDATE_DATE       as LAST_UPDATE_DATE                   --
         , xpsi.LAST_UPDATE_LOGIN      as LAST_UPDATE_LOGIN                  --
         , xpsi.REQUEST_ID             as REQUEST_ID                         --
         , xpsi.PROGRAM_APPLICATION_ID as PROGRAM_APPLICATION_ID             --
         , xpsi.PROGRAM_ID             as PROGRAM_ID                         --
         , xpsi.PROGRAM_UPDATE_DATE    as PROGRAM_UPDATE_DATE                --
        FROM
           XX03_PAYMENT_SLIPS_IF       xpsi
-- ver 11.5.10.2.7 Chg Start
-- -- Ver11.5.10.1.6C Chg Start
-- -- -- Ver11.5.10.1.6B Chg Start
-- -- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION
-- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION,XLXV.ATTRIBUTE14
-- -- -- Ver11.5.10.1.6B Chg End
-- --           FROM XX03_SLIP_TYPES_V XLXV
-- --           WHERE XLXV.ENABLED_FLAG = 'Y'
-- --          )                           xstl
--          ,(SELECT XSTLV.LOOKUP_CODE,XSTLV.DESCRIPTION,XSTLV.ATTRIBUTE14
--            FROM XX03_SLIP_TYPES_LOV_V XSTLV
--            WHERE XSTLV.ATTRIBUTE14 = 'SQLAP'
--            )                           xstl
-- -- Ver11.5.10.1.6C Chg End
         ,(select XSTLV.LOOKUP_CODE , XSTLV.DESCRIPTION , XSTLV.ATTRIBUTE14
             from XX03_SLIP_TYPES_LOV_V XSTLV , FND_FORM_FUNCTIONS FFF
            where XSTLV.ATTRIBUTE14 = 'SQLAP'
              and (   upper(FFF.PARAMETERS) like '%&SLIPTYPECODE=' || XSTLV.LOOKUP_CODE
                   or upper(FFF.PARAMETERS) like '%&SLIPTYPECODE=' || XSTLV.LOOKUP_CODE || '&%'
                   or upper(FFF.PARAMETERS) like 'SLIPTYPECODE='   || XSTLV.LOOKUP_CODE || '&%' )
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
         , XX03_PER_PEOPLES_V          xpp
         , XX03_PER_PEOPLES_V          xpp2
-- Ver11.5.10.1.5B Chg Start
         --, XX03_APPROVER_PERSON_LOV_V  xapl
         , PER_PEOPLE_F                ppf
-- Ver11.5.10.1.5B Chg End
         ,(SELECT PV.VENDOR_ID , PV.SEGMENT1 , PV.SEGMENT1 || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || PV.VENDOR_NAME VENDORS_COL
           FROM PO_VENDORS PV
           WHERE NVL(PV.END_DATE_ACTIVE, TO_DATE('4712/12/31', 'YYYY/MM/DD')) > TRUNC(SYSDATE)
           )                           xvl
         -- ver 11.5.10.2.6 Chg Start
         --,(SELECT PV.SEGMENT1 VENDOR_NUMBER , PVS.VENDOR_SITE_CODE VENDOR_SITE_CODE , PVS.ATTRIBUTE3 AUTO_TAX_CALC_FLAG
         --       , PVS.AP_TAX_ROUNDING_RULE AP_TAX_ROUNDING_RULE , PVS.VENDOR_SITE_ID VENDOR_SITE_ID
         --  FROM PO_VENDORS PV , PO_VENDOR_SITES_ALL PVS , AP_BANK_ACCOUNT_USES_ALL ABAU
         --  WHERE PV.VENDOR_ID = PVS.VENDOR_ID AND PVS.VENDOR_ID = ABAU.VENDOR_ID(+) AND PVS.VENDOR_SITE_ID = ABAU.VENDOR_SITE_ID(+)
         --    AND 'Y' = ABAU.PRIMARY_FLAG(+) AND PVS.PAY_SITE_FLAG = 'Y' AND PVS.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND PVS.AUTO_TAX_CALC_FLAG = 'N'
         --    AND NVL(PVS.INACTIVE_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD')) > TRUNC(SYSDATE) AND NVL(ABAU.END_DATE , TO_DATE('4712/12/31', 'YYYY/MM/DD')) > TRUNC(SYSDATE)
         --  )                           xvsl
         ,(SELECT PV.SEGMENT1 VENDOR_NUMBER ,PVS.VENDOR_SITE_CODE VENDOR_SITE_CODE ,PVS.ATTRIBUTE3 AUTO_TAX_CALC_FLAG ,PVS.AP_TAX_ROUNDING_RULE AP_TAX_ROUNDING_RULE
                 -- ver 11.5.10.2.10D Chg Start
                 --,PVS.VENDOR_SITE_ID VENDOR_SITE_ID ,PVS.PAYMENT_METHOD_LOOKUP_CODE PAYMETHOD ,AP_BANK.NAME BANK_NAME
                 ,PVS.VENDOR_SITE_ID VENDOR_SITE_ID ,AP_BANK.NAME BANK_NAME
                 -- ver 11.5.10.2.10D Chg End
             FROM PO_VENDORS PV ,PO_VENDOR_SITES_ALL PVS
                 ,(SELECT ABAU.VENDOR_ID VENDOR_ID ,ABAU.VENDOR_SITE_ID VENDOR_SITE_ID
                         ,NVL2(ABB.BANK_NAME ,ABB.BANK_NAME || ' ' || ABB.BANK_BRANCH_NAME || ' ' || DECODE(ABA.BANK_ACCOUNT_TYPE, '1', '����', '2', '����', '')
                                              || ' ' || ABA.BANK_ACCOUNT_NUM ,null) NAME
                     FROM AP_BANK_ACCOUNT_USES_ALL ABAU ,AP_BANK_ACCOUNTS_ALL ABA ,AP_BANK_BRANCHES ABB
                    WHERE ABAU.PRIMARY_FLAG  = 'Y' AND TRUNC(SYSDATE) BETWEEN NVL(ABAU.START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(ABAU.END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
                      -- ver 11.5.10.2.10C Chg Start
                      --AND ABA.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND ABAU.EXTERNAL_BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID AND TRUNC(SYSDATE) <= NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
                      --AND ABA.BANK_BRANCH_ID = ABB.BANK_BRANCH_ID AND TRUNC(SYSDATE) <= NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))  ) AP_BANK
                      AND ABA.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND ABAU.EXTERNAL_BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID AND TRUNC(SYSDATE) < NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
                      AND ABA.BANK_BRANCH_ID = ABB.BANK_BRANCH_ID AND TRUNC(SYSDATE) < NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))  ) AP_BANK
                      -- ver 11.5.10.2.10C Chg End
            WHERE PV.VENDOR_ID = PVS.VENDOR_ID AND PVS.PAY_SITE_FLAG = 'Y' AND PVS.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND PVS.VENDOR_ID = AP_BANK.VENDOR_ID (+)
              AND PVS.VENDOR_SITE_ID  = AP_BANK.VENDOR_SITE_ID (+) AND TRUNC(SYSDATE) < NVL(PVS.INACTIVE_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD')) AND PVS.AUTO_TAX_CALC_FLAG = 'N'
           )                           xvsl
         -- ver 11.5.10.2.6 Chg End
         , XX03_CONVERSION_TYPES_V     xct
         ,(SELECT XV.TERM_ID,XV.ATTRIBUTE1,XV.NAME
           FROM XX03_AP_TERMS_V XV
           -- ver 11.5.10.2.6 Chg Start
           --WHERE XV.ENABLED_FLAG = 'Y'  AND NVL(XV.ATTRIBUTE15 ,XX00_PROFILE_PKG.VALUE('ORG_ID')) = XX00_PROFILE_PKG.VALUE('ORG_ID')
           WHERE XV.ENABLED_FLAG = 'Y'
             AND NVL(START_DATE_ACTIVE, TO_DATE('1000/01/01','YYYY/MM/DD')) <= TRUNC(SYSDATE)
             AND TRUNC(SYSDATE) < NVL(END_DATE_ACTIVE  , TO_DATE('4712/12/31','YYYY/MM/DD'))
           -- ver 11.5.10.2.6 Chg End
           )                           xatl
         -- ver 11.5.10.2.10D Chg Start
         --,(SELECT XV.LOOKUP_CODE,XV.MEANING
         ,(SELECT XV.LOOKUP_CODE,XV.MEANING,XV.ATTRIBUTE1
         -- ver 11.5.10.2.10D Add End
           FROM XX03_AP_PAY_GROUPS_V XV
           WHERE XV.ENABLED_FLAG = 'Y'
           -- ver 11.5.10.2.6 Chg Start
             AND TRUNC(SYSDATE) BETWEEN NVL(XV.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                                    AND NVL(XV.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'))
           -- ver 11.5.10.2.6 Chg End
           )                           xapgl
          ,XX03_PREPAYMENT_LOV_V       xpl
        WHERE
              xpsi.REQUEST_ID               = h_request_id
          AND xpsi.SOURCE                   = h_source
          AND xpsi.SLIP_TYPE_NAME           = xstl.DESCRIPTION         (+)
          AND xpsi.REQUESTOR_PERSON_NUMBER  = xpp.EMPLOYEE_NUMBER      (+)
          AND xpsi.ENTRY_PERSON_NUMBER      = xpp2.EMPLOYEE_NUMBER     (+)
-- Ver11.5.10.1.5B Chg Start
          --AND xpsi.APPROVER_PERSON_NUMBER   = xapl.EMPLOYEE_NUMBER     (+)
          AND xpsi.APPROVER_PERSON_NUMBER   = ppf.EMPLOYEE_NUMBER     (+)
          AND TRUNC(SYSDATE) BETWEEN ppf.effective_start_date(+) AND ppf.effective_end_date(+)
          AND ppf.current_employee_flag(+) = 'Y'
-- Ver11.5.10.1.5B Chg End
          AND xpsi.VENDOR_CODE              = xvl.SEGMENT1             (+)
          AND xpsi.VENDOR_CODE              = xvsl.VENDOR_NUMBER       (+)
          AND xpsi.VENDOR_SITE_CODE         = xvsl.VENDOR_SITE_CODE    (+)
          AND xpsi.EXCHANGE_RATE_TYPE_NAME  = xct.USER_CONVERSION_TYPE (+)
          AND xpsi.TERMS_NAME               = xatl.NAME                (+)
          AND xpsi.PAY_GROUP_LOOKUP_NAME    = xapgl.MEANING            (+)
          AND xpsi.PREPAY_NUM               = xpl.INVOICE_NUM          (+)
        ) HEAD
      ,(SELECT /*+ USE_NL(xpsli) */
           xpsli.INTERFACE_ID          as INTERFACE_ID                       -- �C���^�[�t�F�[�XID
         , xpsli.LINE_NUMBER           as LINE_NUMBER                        -- ���C���i���o�[
         , xpsli.SLIP_LINE_TYPE        as SLIP_LINE_TYPE                     -- �E�v�R�[�h
         -- ver 11.5.10.1.6F Add Start
         , xlxv.SLIP_LINE_TYPE_NAME    as SLIP_LINE_TYPE_NAME                -- �E�v�R�[�h����
         -- ver 11.5.10.1.6F Add Start
         , xpsli.ENTERED_ITEM_AMOUNT   as ENTERED_ITEM_AMOUNT                -- �{�̋��z
         , xpsli.ENTERED_TAX_AMOUNT    as ENTERED_TAX_AMOUNT                 -- ����Ŋz
         , xpsli.DESCRIPTION           as DESCRIPTION                        -- ���l
         , xpsli.AMOUNT_INCLUDES_TAX_FLAG  as AMOUNT_INCLUDES_TAX_FLAG       -- ����
         , xpsli.TAX_CODE              as TAX_CODE                           -- �ŋ敪
         , xtcl.TAX_CODES_COL          as TAX_NAME                           -- �ŋ敪��
         , xcl.FLEX_VALUE              as SEGMENT1                           -- ���
         , xcl.COMPANIES_COL           as SEGMENT1_NAME                      -- ��Ж�
         , xdl.FLEX_VALUE              as SEGMENT2                           -- ����
         , xdl.DEPARTMENTS_COL         as SEGMENT2_NAME                      -- ���喼
         , xal.FLEX_VALUE              as SEGMENT3                           -- ����Ȗ�
         , xal.ACCOUNTS_COL            as SEGMENT3_NAME                      -- ����Ȗږ�
         , xsal.FLEX_VALUE             as SEGMENT4                           -- �⏕�Ȗ�
         , xsal.SUB_ACCOUNTS_COL       as SEGMENT4_NAME                      -- �⏕�Ȗږ�
         , xpal.FLEX_VALUE             as SEGMENT5                           -- �����
         , xpal.PARTNERS_COL           as SEGMENT5_NAME                      -- ����於
         , xbtl.FLEX_VALUE             as SEGMENT6                           -- ���Ƌ敪
         , xbtl.BUSINESS_TYPE_COL      as SEGMENT6_NAME                      -- ���Ƌ敪��
         , xprl.FLEX_VALUE             as SEGMENT7                           -- �v���W�F�N�g
         , xprl.PROJECTS_COL           as SEGMENT7_NAME                      -- �v���W�F�N�g��
         , xfl.FLEX_VALUE              as SEGMENT8                           -- �\��
         , xfl.FUTURES_COL             as SEGMENT8_NAME                      -- �\����
         , xpsli.INCR_DECR_REASON_CODE as INCR_DECR_REASON_CODE              -- �������R
         , xidrl.INCR_DECR_REASONS_COL as INCR_DECR_REASON_NAME              -- �������R��
         , xpsli.RECON_REFERENCE       as RECON_REFERENCE                    -- �����Q��
         , xpsli.ORG_ID                as ORG_ID                             -- �I���OID
-- ver 11.5.10.2.10H Add Start
         , xpsli.ATTRIBUTE7            as ATTRIBUTE7                         -- �g�c���ϔԍ�
-- ver 11.5.10.2.10H Add End
         , xpsli.CREATED_BY            as CREATED_BY                         --
         , xpsli.CREATION_DATE         as CREATION_DATE                      --
         , xpsli.LAST_UPDATED_BY       as LAST_UPDATED_BY                    --
         , xpsli.LAST_UPDATE_DATE      as LAST_UPDATE_DATE                   --
         , xpsli.LAST_UPDATE_LOGIN     as LAST_UPDATE_LOGIN                  --
         , xpsli.REQUEST_ID            as REQUEST_ID                         --
         , xpsli.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID           --
         , xpsli.PROGRAM_ID            as PROGRAM_ID                         --
         , xpsli.PROGRAM_UPDATE_DATE   as PROGRAM_UPDATE_DATE                --
      FROM
         -- Ver11.5.10.1.6 2005/12/15 Change Start
         --  XX03_PAYMENT_SLIP_LINES_IF  xpsli
         --,(SELECT XV.NAME,XV.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION TAX_CODES_COL
         --  FROM XX03_TAX_CODES_V XV
         --  WHERE XV.ENABLED_FLAG = 'Y'
         --  )                           xtcl
         -- ver 11.5.10.1.6F Chg Start
         --  XX03_PAYMENT_SLIPS_IF       xpsi
         --, XX03_PAYMENT_SLIP_LINES_IF  xpsli
         --,(SELECT XV.NAME,XV.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION TAX_CODES_COL,
         --         XV.START_DATE, XV.INACTIVE_DATE
         --  FROM XX03_TAX_CODES_V XV
         --  WHERE XV.ENABLED_FLAG = 'Y'
         --  )                           xtcl
          XX03_PAYMENT_SLIP_LINES_IF  xpsli
         ,(SELECT XV.NAME,XV.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION TAX_CODES_COL
--                 ,XV.START_DATE, XV.INACTIVE_DATE
                 ,xpsli.INTERFACE_ID
                 ,xpsli.LINE_NUMBER
           FROM XX03_TAX_CODES_V            XV
              , XX03_PAYMENT_SLIPS_IF       xpsi
              , XX03_PAYMENT_SLIP_LINES_IF  xpsli
           WHERE XV.ENABLED_FLAG = 'Y'
             AND xpsli.TAX_CODE = XV.NAME
             AND xpsi.INTERFACE_ID = xpsli.INTERFACE_ID
             AND xpsi.INVOICE_DATE BETWEEN NVL(XV.START_DATE    ,TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                                       AND NVL(XV.INACTIVE_DATE ,TO_DATE('4712/12/31', 'YYYY/MM/DD'))
             -- ver 11.5.10.2.5B Add Start
             AND xpsi.REQUEST_ID   = h_request_id
             AND xpsi.SOURCE       = h_source
             AND xpsli.REQUEST_ID  = h_request_id
             AND xpsli.SOURCE      = h_source
             -- ver 11.5.10.2.5B Add End
           )                           xtcl
         -- ver 11.5.10.1.6F Chg End
         -- Ver11.5.10.1.6 2005/12/15 Change End
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION COMPANIES_COL
           FROM XX03_COMPANIES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xcl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION DEPARTMENTS_COL
           FROM XX03_DEPARTMENTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xdl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION ACCOUNTS_COL
           FROM XX03_ACCOUNTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'  AND XV.ATTRIBUTE5 IS NOT NULL
           )                           xal
         ,(SELECT XV.PARENT_FLEX_VALUE_LOW,XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION SUB_ACCOUNTS_COL
           FROM XX03_SUB_ACCOUNTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xsal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION PARTNERS_COL
           FROM XX03_PARTNERS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xpal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION BUSINESS_TYPE_COL
           FROM XX03_BUSINESS_TYPES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xbtl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION PROJECTS_COL
           FROM XX03_PROJECTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xprl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION FUTURES_COL
           FROM XX03_FUTURES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xfl
         ,(SELECT XV.FFL_FLEX_VALUE FLEX_VALUE,XV.FFL_FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION INCR_DECR_REASONS_COL,XCC.ACCOUNT_CODE PARENT_FLEX_VALUE_LOW
           FROM XX03_INCR_DECR_REASONS_V XV
               ,XX03_CF_COMBINATIONS XCC
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND XCC.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') AND XCC.INCR_DECR_REASON_CODE = XV.FFL_FLEX_VALUE
           )                           xidrl
         -- ver 11.5.10.1.6F Add Start
         -- ver 11.5.10.2.10B Chg Start
         --,(SELECT XV.LOOKUP_CODE LOOKUP_CODE ,XV.DESCRIPTION SLIP_LINE_TYPE_NAME
         ,(SELECT XV.LOOKUP_CODE LOOKUP_CODE
                 ,XV.LOOKUP_CODE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION SLIP_LINE_TYPE_NAME
         -- ver 11.5.10.2.10B Chg End
--                 ,XV.START_DATE_ACTIVE START_DATE_ACTIVE ,XV.END_DATE_ACTIVE END_DATE_ACTIVE
                 ,xpsli.INTERFACE_ID
                 ,xpsli.LINE_NUMBER
           FROM XX03_LOOKUPS_XX03_V         XV
              , XX03_PAYMENT_SLIPS_IF       xpsi
              , XX03_PAYMENT_SLIP_LINES_IF  xpsli
           WHERE  XV.LANGUAGE = USERENV('LANG')  AND XV.LOOKUP_TYPE = 'XX03_SLIP_LINE_TYPES'  AND XV.ATTRIBUTE15 = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND XV.ENABLED_FLAG = 'Y'
             AND xpsi.INTERFACE_ID    = xpsli.INTERFACE_ID
             AND xpsli.SLIP_LINE_TYPE = XV.LOOKUP_CODE
             AND xpsi.INVOICE_DATE BETWEEN NVL(XV.START_DATE_ACTIVE ,TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                                       AND NVL(XV.END_DATE_ACTIVE   ,TO_DATE('4712/12/31', 'YYYY/MM/DD'))
             -- ver 11.5.10.2.5B Add Start
             AND xpsi.REQUEST_ID   = h_request_id
             AND xpsi.SOURCE       = h_source
             AND xpsli.REQUEST_ID  = h_request_id
             AND xpsli.SOURCE      = h_source
             -- ver 11.5.10.2.5B Add End
           )                           xlxv
         -- ver 11.5.10.1.6F Add End
      WHERE
            xpsli.REQUEST_ID                = h_request_id
        AND xpsli.SOURCE                    = h_source
        -- ver 11.5.10.1.6F Chg Start
        --AND xpsli.TAX_CODE                  = xtcl.NAME                   (+)
        ---- Ver11.5.10.1.6 2005/12/15 Add Start
        --AND xpsi.INTERFACE_ID               = xpsli.INTERFACE_ID
        --AND xpsi.INVOICE_DATE BETWEEN NVL(xtcl.START_DATE    ,TO_DATE('1000/01/01', 'YYYY/MM/DD'))
        --                          AND NVL(xtcl.INACTIVE_DATE ,TO_DATE('4712/12/31', 'YYYY/MM/DD'))
        AND xpsli.INTERFACE_ID              = xtcl.INTERFACE_ID           (+)
        AND xpsli.LINE_NUMBER               = xtcl.LINE_NUMBER            (+)
        ---- Ver11.5.10.1.6 2005/12/15 Add End
        -- ver 11.5.10.1.6F Chg End
        AND xpsli.SEGMENT1                  = xcl.FLEX_VALUE              (+)
        AND xpsli.SEGMENT2                  = xdl.FLEX_VALUE              (+)
        AND xpsli.SEGMENT3                  = xal.FLEX_VALUE              (+)
        AND xpsli.SEGMENT3                  = xsal.PARENT_FLEX_VALUE_LOW  (+)
        AND xpsli.SEGMENT4                  = xsal.FLEX_VALUE             (+)
        AND xpsli.SEGMENT5                  = xpal.FLEX_VALUE             (+)
        AND xpsli.SEGMENT6                  = xbtl.FLEX_VALUE             (+)
        AND xpsli.SEGMENT7                  = xprl.FLEX_VALUE             (+)
        AND xpsli.SEGMENT8                  = xfl.FLEX_VALUE              (+)
        AND xpsli.SEGMENT3                  = xidrl.PARENT_FLEX_VALUE_LOW (+)
        AND xpsli.INCR_DECR_REASON_CODE     = xidrl.FLEX_VALUE            (+)
        -- ver 11.5.10.1.6F Add Start
        AND xpsli.INTERFACE_ID              = xlxv.INTERFACE_ID           (+)
        AND xpsli.LINE_NUMBER               = xlxv.LINE_NUMBER            (+)
        -- ver 11.5.10.1.6F Add End
        ) LINE
      ,(SELECT /*+ USE_NL(xpsic) */
               xpsic.INTERFACE_ID         as INTERFACE_ID
              ,COUNT(xpsic.INTERFACE_ID)  as REC_COUNT
        FROM   XX03_PAYMENT_SLIPS_IF xpsic
        WHERE  xpsic.REQUEST_ID = h_request_id
          AND  xpsic.SOURCE     = h_source
        GROUP BY xpsic.INTERFACE_ID
        ) CNT
      -- ver 11.5.10.2.10E Add Start
      ,(SELECT /*+ USE_NL(xpsi) */
           xpsi.INTERFACE_ID as INTERFACE_ID
          ,ppf.PERSON_ID     as PERSON_ID
        FROM
           XX03_PAYMENT_SLIPS_IF xpsi
         ,(SELECT employee_number ,person_id FROM PER_PEOPLE_F
           WHERE current_employee_flag = 'Y' AND TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date
           ) ppf
        WHERE
              xpsi.APPROVER_PERSON_NUMBER = ppf.EMPLOYEE_NUMBER
          -- ver 11.5.10.2.10I Add Start
          AND  xpsi.request_id             = h_request_id
          AND  xpsi.source                 = h_source
          -- ver 11.5.10.2.10I Add End
          AND EXISTS (SELECT '1'
                      FROM   XX03_APPROVER_PERSON_LOV_V xaplv
                      WHERE  xaplv.PERSON_ID = ppf.person_id
                        AND (   xaplv.PROFILE_VAL_DEP = 'ALL'
                      -- ver 11.5.10.2.10F Chg Start
                      --       or xaplv.PROFILE_VAL_DEP = 'SQLGL')
                             or xaplv.PROFILE_VAL_DEP = 'SQLAP')
                      -- ver 11.5.10.2.10F Chg End
                      )
        ) APPROVER
      -- ver 11.5.10.2.10E Add End
    WHERE
          HEAD.INTERFACE_ID = LINE.INTERFACE_ID
      AND HEAD.INTERFACE_ID = CNT.INTERFACE_ID
      -- ver 11.5.10.2.10E Add Start
      AND HEAD.INTERFACE_ID = APPROVER.INTERFACE_ID(+)
      -- ver 11.5.10.2.10E Add End
    ORDER BY
       HEAD.INTERFACE_ID ,LINE.LINE_NUMBER
    ;
--
    -- �w�b�_���׏��J�[�\�����R�[�h�^
    xx03_if_head_line_rec  xx03_if_head_line_cur%ROWTYPE;
--
-- Ver11.5.10.1.5 2005/09/05 Add End
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  same_id_header_expt      EXCEPTION;     -- �w�b�_���R�[�h�d������
  get_slip_type_expt       EXCEPTION;     -- �`�[��ʓ��͒l�Ȃ�
  get_approver_expt        EXCEPTION;     -- ���F�ғ��͒l�Ȃ�
  get_vendor_expt          EXCEPTION;     -- �d������͒l�Ȃ�
  get_vendor_site_expt     EXCEPTION;     -- �d����T�C�g���͒l�Ȃ�
  get_invoice_date_expt    EXCEPTION;     -- ���������t���͒l�Ȃ�
  get_gl_date_expt         EXCEPTION;     -- �v������͒l�Ȃ�
  get_pay_group_expt       EXCEPTION;     -- �x���O���[�v���͒l�Ȃ�
  get_terms_name_expt      EXCEPTION;     -- �x���������͒l�Ȃ�
  get_cur_code_expt        EXCEPTION;     -- �ʉݓ��͒l�Ȃ�
  check_pkg_err_expt       EXCEPTION;     -- ���ʃG���[
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
-- Ver11.5.10.1.5 2005/09/05 Change Start
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
--    ln_amount NUMBER;      -- ���z
--    lv_slip_type_name VARCHAR2(4000);  -- �E�v����
----
--    -- ===============================
--    -- ���[�J���E�J�[�\��
--    -- ===============================
--    -- ���׏��J�[�\��
--    CURSOR xx03_if_detail_cur(h_source VARCHAR2,
--                                h_request_id NUMBER,
--                                h_interface_id NUMBER,
--                                h_currency_code VARCHAR2)
--    IS
--      SELECT
--        xpsli.INTERFACE_ID as INTERFACE_ID,                           -- �C���^�[�t�F�[�XID
--        xpsli.SLIP_LINE_TYPE as SLIP_LINE_TYPE,                       -- �E�v�R�[�h
--        TO_NUMBER(TO_CHAR(xpsli.ENTERED_ITEM_AMOUNT,
--                    xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                    xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--                 ) as ENTERED_ITEM_AMOUNT,                           -- �{�̋��z
--        TO_NUMBER(TO_CHAR(xpsli.ENTERED_TAX_AMOUNT,
--                    xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                    xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--                 ) as ENTERED_TAX_AMOUNT,                            -- ����Ŋz
--        xpsli.DESCRIPTION as DESCRIPTION,                             -- ���l
--        xpsli.AMOUNT_INCLUDES_TAX_FLAG as AMOUNT_INCLUDES_TAX_FLAG,   -- ����
--        xpsli.TAX_CODE as TAX_CODE,                                   -- �ŋ敪
--        xtcl.TAX_CODES_COL as TAX_NAME,                               -- �ŋ敪��
--        xpsli.SEGMENT1 as SEGMENT1,                                   -- ���
--        xpsli.SEGMENT2 as SEGMENT2,                                   -- ����
--        xpsli.SEGMENT3 as SEGMENT3,                                   -- ����Ȗ�
--        xpsli.SEGMENT4 as SEGMENT4,                                   -- �⏕�Ȗ�
--        xpsli.SEGMENT5 as SEGMENT5,                                   -- �����
--        xpsli.SEGMENT6 as SEGMENT6,                                   -- ���Ƌ敪
--        xpsli.SEGMENT7 as SEGMENT7,                                   -- �v���W�F�N�g
--        xpsli.SEGMENT8 as SEGMENT8,                                   -- �\��
--        xcl.COMPANIES_COL as SEGMENT1_NAME,                           -- ��Ж�
--        xdl.DEPARTMENTS_COL as SEGMENT2_NAME,                         -- ���喼
--        xal.ACCOUNTS_COL as SEGMENT3_NAME,                            -- ����Ȗږ�
--        xsal.SUB_ACCOUNTS_COL as SEGMENT4_NAME,                       -- �⏕�Ȗږ�
--        xpal.PARTNERS_COL as SEGMENT5_NAME,                           -- ����於
--        xbtl.BUSINESS_TYPES_COL as SEGMENT6_NAME,                     -- ���Ƌ敪��
--        xprl.PROJECTS_COL as SEGMENT7_NAME,                           -- �v���W�F�N�g��
--        xpsli.SEGMENT8 as SEGMENT8_NAME,                              -- �\��
--        xpsli.INCR_DECR_REASON_CODE as INCR_DECR_REASON_CODE,         -- �������R
--        xidrl.INCR_DECR_REASONS_COL as INCR_DECR_REASON_NAME,         -- �������R��
--        xpsli.RECON_REFERENCE as RECON_REFERENCE,                     -- �����Q��
--        xpsli.ORG_ID as ORG_ID,                                       -- �I���OID
--        xpsli.CREATED_BY,
--        xpsli.CREATION_DATE,
--        xpsli.LAST_UPDATED_BY,
--        xpsli.LAST_UPDATE_DATE,
--        xpsli.LAST_UPDATE_LOGIN,
--        xpsli.REQUEST_ID,
--        xpsli.PROGRAM_APPLICATION_ID,
--        xpsli.PROGRAM_ID,
--        xpsli.PROGRAM_UPDATE_DATE
--      FROM
--        XX03_PAYMENT_SLIP_LINES_IF xpsli,
--        XX03_TAX_CODES_LOV_V xtcl,
--        XX03_COMPANIES_LOV_V xcl,
--        XX03_DEPARTMENTS_LOV_V xdl,
--        XX03_ACCOUNTS_LOV_V xal,
--        XX03_SUB_ACCOUNTS_LOV_V xsal,
--        XX03_PARTNERS_LOV_V xpal,
--        XX03_BUSINESS_TYPES_LOV_V xbtl,
--        XX03_PROJECTS_LOV_V xprl,
--        XX03_INCR_DECR_REASONS_LOV_V xidrl
--      WHERE
--        xpsli.REQUEST_ID = h_request_id
--        AND xpsli.SOURCE = h_source
--        AND xpsli.INTERFACE_ID = h_interface_id
--        AND xpsli.TAX_CODE = xtcl.NAME (+)
--        AND xpsli.SEGMENT1 = xcl.FLEX_VALUE (+)
--        AND xpsli.SEGMENT2 = xdl.FLEX_VALUE (+)
--        AND xpsli.SEGMENT3 = xal.FLEX_VALUE (+)
--        AND xpsli.SEGMENT4 = xsal.FLEX_VALUE (+)
--        AND xpsli.SEGMENT3 = xsal.PARENT_FLEX_VALUE_LOW (+)
--        AND xpsli.SEGMENT5 = xpal.FLEX_VALUE (+)
--        AND xpsli.SEGMENT6 = xbtl.FLEX_VALUE (+)
--        AND xpsli.SEGMENT7 = xprl.FLEX_VALUE (+)
--        AND xpsli.INCR_DECR_REASON_CODE = xidrl.FLEX_VALUE (+)
--        AND xpsli.SEGMENT3 = xidrl.PARENT_FLEX_VALUE_LOW (+)
--      ORDER BY
--        xpsli.LINE_NUMBER;
--    -- ���׏��J�[�\�����R�[�h�^
--    xx03_if_detail_rec xx03_if_detail_cur%ROWTYPE;
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
--    -- ���טA�ԏ�����
--    ln_line_count := 1;
--    -- ���׏��J�[�\���I�[�v��
--    OPEN xx03_if_detail_cur(iv_source,
--                              in_request_id,
--                              xx03_if_header_rec.INTERFACE_ID,
--                              xx03_if_header_rec.INVOICE_CURRENCY_CODE);
--    <<xx03_if_detail_loop>>
--    LOOP
--      FETCH xx03_if_detail_cur INTO xx03_if_detail_rec;
--      IF xx03_if_detail_cur%NOTFOUND THEN
--        -- �Ώۃf�[�^���Ȃ��Ȃ�܂Ń��[�v
--        EXIT xx03_if_detail_loop;
--      END IF;
----
--      -- ����ID�擾
--      SELECT XX03_PAYMENT_SLIP_LINES_S.nextval
--        INTO ln_line_id
--        FROM dual;
----
--      -- �E�v���̎擾
--      BEGIN
--        SELECT xsltl.SLIP_LINE_TYPES_COL as SLIP_LINE_TYPE_NAME
--          INTO lv_slip_type_name
--          FROM XX03_SLIP_LINE_TYPES_LOV_V xsltl
--         WHERE xsltl.LOOKUP_CODE = xx03_if_detail_rec.SLIP_LINE_TYPE
--           AND xsltl.VENDOR_SITE_ID = xx03_if_header_rec.VENDOR_SITE_ID;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- �Ώۃf�[�^�Ȃ����͓E�v���̋�
--          lv_slip_type_name := '';
--          -- �X�e�[�^�X���G���[��
--          gv_result := cv_result_error;
--          -- �G���[�������Z
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-08026',
--              'TOK_XX03_LINE_NUMBER',
--              ln_line_count
--            )
--          );
--      END;
----
--      -- ���z�Z�o
--      IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG = cv_yes ) THEN
--        -- '����'��'Y'�̎��͋��z��'�{�̋��z+����Ŋz'
--        ln_amount := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT +
--                      xx03_if_detail_rec.ENTERED_TAX_AMOUNT;
--      ELSIF  ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG = cv_no ) THEN
--        -- '����'��'N'�̎��͋��z��'�{�̋��z'
--        ln_amount := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT;
--      ELSE
--        -- ����ȊO�̎��͓��œ��͒l�G���[
--        ln_amount := 0;
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
--      -- ���׃f�[�^�ۑ�
--      INSERT INTO XX03_PAYMENT_SLIP_LINES(
--        INVOICE_LINE_ID           ,
--        INVOICE_ID                ,
--        LINE_NUMBER               ,
--        SLIP_LINE_TYPE            ,
--        SLIP_LINE_TYPE_NAME       ,
--        ENTERED_AMOUNT            ,
--        ENTERED_ITEM_AMOUNT       ,
--        ENTERED_TAX_AMOUNT        ,
--        DESCRIPTION               ,
--        AMOUNT_INCLUDES_TAX_FLAG  ,
--        TAX_CODE                  ,
--        TAX_NAME                  ,
--        SEGMENT1                  ,
--        SEGMENT2                  ,
--        SEGMENT3                  ,
--        SEGMENT4                  ,
--        SEGMENT5                  ,
--        SEGMENT6                  ,
--        SEGMENT7                  ,
--        SEGMENT8                  ,
--        SEGMENT9                  ,
--        SEGMENT10                 ,
--        SEGMENT11                 ,
--        SEGMENT12                 ,
--        SEGMENT13                 ,
--        SEGMENT14                 ,
--        SEGMENT15                 ,
--        SEGMENT16                 ,
--        SEGMENT17                 ,
--        SEGMENT18                 ,
--        SEGMENT19                 ,
--        SEGMENT20                 ,
--        SEGMENT1_NAME             ,
--        SEGMENT2_NAME             ,
--        SEGMENT3_NAME             ,
--        SEGMENT4_NAME             ,
--        SEGMENT5_NAME             ,
--        SEGMENT6_NAME             ,
--        SEGMENT7_NAME             ,
--        SEGMENT8_NAME             ,
--        INCR_DECR_REASON_CODE     ,
--        INCR_DECR_REASON_NAME     ,
--        RECON_REFERENCE           ,
--        ORG_ID                    ,
--        ATTRIBUTE_CATEGORY        ,
--        ATTRIBUTE1                ,
--        ATTRIBUTE2                ,
--        ATTRIBUTE3                ,
--        ATTRIBUTE4                ,
--        ATTRIBUTE5                ,
--        ATTRIBUTE6                ,
--        ATTRIBUTE7                ,
--        ATTRIBUTE8                ,
--        ATTRIBUTE9                ,
--        ATTRIBUTE10               ,
--        ATTRIBUTE11               ,
--        ATTRIBUTE12               ,
--        ATTRIBUTE13               ,
--        ATTRIBUTE14               ,
--        ATTRIBUTE15               ,
--        CREATED_BY                ,
--        CREATION_DATE             ,
--        LAST_UPDATED_BY           ,
--        LAST_UPDATE_DATE          ,
--        LAST_UPDATE_LOGIN         ,
--        REQUEST_ID                ,
--        PROGRAM_APPLICATION_ID    ,
--        PROGRAM_ID                ,
--        PROGRAM_UPDATE_DATE
--      )
--      VALUES(
--        ln_line_id,
--        gn_invoice_id,
--        ln_line_count,
--        xx03_if_detail_rec.SLIP_LINE_TYPE,
--        lv_slip_type_name,
--        ln_amount,
--        xx03_if_detail_rec.ENTERED_ITEM_AMOUNT,
--        xx03_if_detail_rec.ENTERED_TAX_AMOUNT,
--        xx03_if_detail_rec.DESCRIPTION,
--        xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG,
--        xx03_if_detail_rec.TAX_CODE,
--        xx03_if_detail_rec.TAX_NAME,
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
--      ln_line_count := ln_line_count + 1;
----
--    END LOOP xx03_if_detail_loop;
--    CLOSE xx03_if_detail_cur;
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
--   * Description      : �������f�[�^�̓��̓`�F�b�N(E-2)
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
--    -- �d����`�F�b�N
--    IF ( xx03_if_header_rec.VENDOR_ID IS NULL
--           OR TRIM(xx03_if_header_rec.VENDOR_ID) = '' ) THEN
--      -- �d����ID����̏ꍇ�͎d������̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08012'
--        )
--      );
--    END IF;
----
--    -- �d����T�C�g�`�F�b�N
--    IF ( xx03_if_header_rec.VENDOR_SITE_ID IS NULL
--           OR TRIM(xx03_if_header_rec.VENDOR_SITE_ID) = '' ) THEN
--      -- �d����T�C�gID����̏ꍇ�͎d����T�C�g���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08013'
--        )
--      );
--    END IF;
----
--    -- ���������t�`�F�b�N
--    IF ( xx03_if_header_rec.INVOICE_DATE IS NULL
--           OR TRIM(xx03_if_header_rec.INVOICE_DATE) = '' ) THEN
--      -- ���������t����̏ꍇ�͐��������t���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08014'
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
--    -- �x���O���[�v�`�F�b�N
--    IF ( xx03_if_header_rec.PAY_GROUP_LOOKUP_CODE IS NULL
--           OR TRIM(xx03_if_header_rec.PAY_GROUP_LOOKUP_CODE) = '' ) THEN
--      -- �x���O���[�v����̏ꍇ�͎x���O���[�v���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08016'
--        )
--      );
--    END IF;
----
--    -- �x�������`�F�b�N
--    IF ( xx03_if_header_rec.TERMS_ID IS NULL
--           OR TRIM(xx03_if_header_rec.TERMS_ID) = '' ) THEN
--      -- �x������ID����̏ꍇ�͎x���������̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08017'
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
--    -- �x�������A�x���\����֘A���`�F�b�N
--    IF (( xx03_if_header_rec.TERMS_CHANGE_FLG = cv_yes
--          AND ( xx03_if_header_rec.TERMS_DATE IS NULL
--                OR TRIM(xx03_if_header_rec.TERMS_DATE) = ''))
--        OR ( xx03_if_header_rec.TERMS_CHANGE_FLG = cv_no
--          AND ( xx03_if_header_rec.TERMS_DATE IS NOT NULL
--                OR TRIM(xx03_if_header_rec.TERMS_DATE) <> ''))) THEN
--      -- �x���\����ύX�s�œ��͂���A�������͎x���\����ύX�œ��͂Ȃ��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08019'
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
--    ln_total_item_amount NUMBER; -- �{�̋��z���v
--    ln_total_tax_amount NUMBER;  -- ����Ŋz���v
--    ln_prepay_amount NUMBER;     -- �O�����z
--    lv_cur_code VARCHAR2(15);    -- �@�\�ʉ݃R�[�h
--    ln_accounted_amount NUMBER;  -- ���Z�ύ��v���z
--    wk number;
----
--  BEGIN
----
----##################  �Œ�X�e�[�^�X�������� START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  �Œ蕔 END   ############################
----
---- 20050217 V1.2 START
---- �����ǉ��yORG_ID�z
--    -- �{�̋��z���v�Z�o
--    SELECT SUM(xpsl.ENTERED_ITEM_AMOUNT) as ENTERED_ITEM_AMOUNT
--      INTO ln_total_item_amount
--      FROM XX03_PAYMENT_SLIP_LINES xpsl
--     WHERE xpsl.INVOICE_ID = gn_invoice_id
--       AND xpsl.ORG_ID = gn_org_id
--    GROUP BY xpsl.INVOICE_ID;
----
--    -- �w�b�_���R�[�h�ɖ{�̍��v���z�Z�b�g
--    UPDATE XX03_PAYMENT_SLIPS xps
--       SET xps.INV_ITEM_AMOUNT = ln_total_item_amount
--     WHERE xps.INVOICE_ID = gn_invoice_id
--       AND xps.ORG_ID = gn_org_id;
----
--    -- ����Ŋz���v
--    SELECT SUM(xpsl.ENTERED_TAX_AMOUNT) as ENTERED_TAX_AMOUNT
--      INTO ln_total_tax_amount
--      FROM XX03_PAYMENT_SLIP_LINES xpsl
--     WHERE xpsl.INVOICE_ID = gn_invoice_id
--       AND xpsl.ORG_ID = gn_org_id
--    GROUP BY xpsl.INVOICE_ID;
----
--    -- �w�b�_���R�[�h�ɖ{�̍��v���z�Z�b�g
--    UPDATE XX03_PAYMENT_SLIPS xps
--       SET xps.INV_TAX_AMOUNT = ln_total_tax_amount
--     WHERE xps.INVOICE_ID = gn_invoice_id
--       AND xps.ORG_ID = gn_org_id;
----
--    -- �[�����z�v�Z
--    IF ( xx03_if_header_rec.PREPAY_NUM IS NOT NULL ) THEN
--      -- �[���`�[����
--      BEGIN
--        SELECT xpl.PREPAY_AMOUNT_APPLIED
--          INTO ln_prepay_amount
--          FROM XX03_PREPAYMENT_LOV_V xpl
--         WHERE xpl.INVOICE_NUM = xx03_if_header_rec.PREPAY_NUM;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- �Ώۃf�[�^�Ȃ����͏����𔲂���
--          -- �X�e�[�^�X���G���[��
--          gv_result := cv_result_error;
--          -- �G���[�������Z
--          gn_error_count := gn_error_count + 1;
--          RETURN;
--      END;
--      -- ���R�[�h�̏[�����z�ƁA�{�̋��z�{����Ŋz�̏����������[�����z�Ƃ���
--      IF ( ln_prepay_amount > (ln_total_item_amount + ln_total_tax_amount)) THEN
--        ln_prepay_amount := ln_total_item_amount + ln_total_tax_amount;
--      END IF;
---- 20050217 V1.2 START
---- �����ǉ��yORG_ID�z
--      -- �w�b�_���R�[�h�ɏ[�����z�Z�b�g
--      UPDATE XX03_PAYMENT_SLIPS xps
--         SET xps.INV_PREPAY_AMOUNT = ln_prepay_amount
--       WHERE xps.INVOICE_ID = gn_invoice_id
--         AND xps.ORG_ID = gn_org_id;
---- 20050217 V1.2 END
--    ELSE
--      -- �[���`�[�Ȃ�
--      ln_prepay_amount := 0;
--    END IF;
----
---- 20050217 V1.2 START
---- �����ǉ��yORG_ID�z
--    -- �x�����z�v�Z
--    -- �w�b�_���R�[�h�Ɏx�����z�Z�b�g
--    UPDATE XX03_PAYMENT_SLIPS xps
--       SET xps.INV_AMOUNT = (ln_total_item_amount + ln_total_tax_amount) - ln_prepay_amount
--     WHERE xps.INVOICE_ID = gn_invoice_id
--       AND xps.ORG_ID = gn_org_id;
---- 20050217 V1.2 END
----
--   -- ���Z�ύ��v���z�v�Z
--   -- �@�\�ʉ݃R�[�h�擾
--   SELECT gsob.currency_code
--     INTO lv_cur_code
--     FROM gl_sets_of_books gsob
--    WHERE gsob.set_of_books_id = xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
----
--   IF ( xx03_if_header_rec.INVOICE_CURRENCY_CODE = lv_cur_code ) THEN
---- 20050217 V1.2 START
---- �����ǉ��yORG_ID�z
--     --�ʉ݃R�[�h���@�\�ʉ݂̏ꍇ�͊��Z�ύ��v���z�Ɏx�����z���Z�b�g
--     UPDATE XX03_PAYMENT_SLIPS xps
--        SET xps.INV_ACCOUNTED_AMOUNT = (ln_total_item_amount + ln_total_tax_amount)
--                                         - ln_prepay_amount
--      WHERE xps.INVOICE_ID = gn_invoice_id
--        AND xps.ORG_ID = org_id;
---- 20050217 V1.2 END
--   ELSE
--     --�ʉ݃R�[�h���@�\�ʉ݂łȂ��ꍇ�͎x�����z�����[�g���Z���Ċ��Z�ύ��v���z�Z�b�g
--     SELECT TO_NUMBER(
--              TO_CHAR(
--                (((ln_total_item_amount + ln_total_tax_amount) - ln_prepay_amount)
--                  * xx03_if_header_rec.EXCHANGE_RATE),
--                xx00_currency_pkg.get_format_mask(lv_cur_code, 38)
--              ),
--              xx00_currency_pkg.get_format_mask(lv_cur_code, 38)
--            )
--       INTO ln_accounted_amount
--       FROM dual;
----
---- 20050217 V1.2 START
---- �����ǉ��yORG_ID�z
--     UPDATE XX03_PAYMENT_SLIPS xps
--        SET xps.INV_ACCOUNTED_AMOUNT = ln_accounted_amount
--      WHERE xps.INVOICE_ID = gn_invoice_id
--        AND xps.ORG_ID = gn_org_id;
---- 20050217 V1.2 END
--   END IF;
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
---- 20050217 V1.2 START
--    -- �I���OID�̎擾
--    gn_org_id := TO_NUMBER(xx00_profile_pkg.value('ORG_ID'));
---- 20050217 V1.2 END
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
--      SELECT COUNT(xpsi.INTERFACE_ID)
--        INTO ln_header_count
--        FROM XX03_PAYMENT_SLIPS_IF xpsi
--       WHERE xpsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID
--         AND xpsi.REQUEST_ID = in_request_id
--         AND xpsi.SOURCE = iv_source;
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
--          -- ===============================
--          -- �x���\����擾(E-4)
--          -- ===============================
--          xx03_deptinput_ap_check_pkg.get_terms_date(
--            xx03_if_header_rec.TERMS_ID,
--            xx03_if_header_rec.INVOICE_DATE,
--            xx03_if_header_rec.TERMS_DATE,
--            ld_terms_date,
--            lv_terms_flg,
--            lv_errbuf,
--            lv_retcode,
--            lv_errmsg
--          );
--          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
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
--                'APP-XX03-14101',
--                'TOK_XX03_CHECK_ERROR',
--                lv_errmsg
--              )
--            );
--          END IF;
----
--          -- �G���[�����o����Ă��Ȃ����݈̂ȍ~�̏������s
--          IF ( gn_error_count = 0 ) THEN
----
--            -- ������ID�擾
--            SELECT XX03_PAYMENT_SLIPS_S.nextval
--              INTO gn_invoice_id
--              FROM dual;
----
--            -- �C���^�[�t�F�[�X�e�[�u��������ID�X�V
--            UPDATE XX03_PAYMENT_SLIPS_IF xpsi
--               SET INVOICE_ID = gn_invoice_id
--             WHERE xpsi.REQUEST_ID = in_request_id
--               AND xpsi.SOURCE = iv_source
--               AND xpsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID;
----
--            -- �w�b�_�f�[�^�ۑ�
--            INSERT INTO XX03_PAYMENT_SLIPS(
--              INVOICE_ID                   ,
--              WF_STATUS                    ,
--              SLIP_TYPE                    ,
--              INVOICE_NUM                  ,
--              ENTRY_DATE                   ,
--              REQUEST_KEY                  ,
--              REQUESTOR_PERSON_ID          ,
--              REQUESTOR_PERSON_NAME        ,
--              APPROVER_PERSON_ID           ,
--              APPROVER_PERSON_NAME         ,
--              REQUEST_DATE                 ,
--              APPROVAL_DATE                ,
--              REJECTION_DATE               ,
--              ACCOUNT_APPROVER_PERSON_ID   ,
--              ACCOUNT_APPROVAL_DATE        ,
--              AP_FORWORD_DATE              ,
--              RECOGNITION_CLASS            ,
--              APPROVER_COMMENTS            ,
--              REQUEST_ENABLE_FLAG          ,
--              ACCOUNT_REVISION_FLAG        ,
--              INVOICE_DATE                 ,
--              VENDOR_ID                    ,
--              VENDOR_NAME                  ,
--              VENDOR_SITE_ID               ,
--              VENDOR_SITE_NAME             ,
--              INV_AMOUNT                   ,
--              INV_ACCOUNTED_AMOUNT         ,
--              INV_ITEM_AMOUNT              ,
--              INV_TAX_AMOUNT               ,
--              INV_PREPAY_AMOUNT            ,
--              INVOICE_CURRENCY_CODE        ,
--              EXCHANGE_RATE                ,
--              EXCHANGE_RATE_TYPE           ,
--              EXCHANGE_RATE_TYPE_NAME      ,
--              TERMS_ID                     ,
--              TERMS_NAME                   ,
--              DESCRIPTION                  ,
--              VENDOR_INVOICE_NUM           ,
--              ENTRY_DEPARTMENT             ,
--              ENTRY_PERSON_ID              ,
--              ORIG_INVOICE_NUM             ,
--              ACCOUNT_APPROVAL_FLAG        ,
--              PAY_GROUP_LOOKUP_CODE        ,
--              PAY_GROUP_LOOKUP_NAME        ,
--              GL_DATE                      ,
--              ACCTS_PAY_CODE_COMBINATION_ID,
--              AUTO_TAX_CALC_FLAG           ,
--              AP_TAX_ROUNDING_RULE         ,
--              PREPAY_NUM                   ,
--              TERMS_DATE                   ,
--              FORM_SELECT_FLAG             ,
-- -- 2005/04/05 Ver11.5.10.1.0 ADD Start
--              DELETE_FLAG                  ,
-- -- 2005/04/05 Ver11.5.10.1.0 ADD End
--              ORG_ID                       ,
--              ATTRIBUTE_CATEGORY           ,
--              ATTRIBUTE1                   ,
--              ATTRIBUTE2                   ,
--              ATTRIBUTE3                   ,
--              ATTRIBUTE4                   ,
--              ATTRIBUTE5                   ,
--              ATTRIBUTE6                   ,
--              ATTRIBUTE7                   ,
--              ATTRIBUTE8                   ,
--              ATTRIBUTE9                   ,
--              ATTRIBUTE10                  ,
--              ATTRIBUTE11                  ,
--              ATTRIBUTE12                  ,
--              ATTRIBUTE13                  ,
--              ATTRIBUTE14                  ,
--              ATTRIBUTE15                  ,
--              ATTRIBUTE16                  ,
--              ATTRIBUTE17                  ,
--              ATTRIBUTE18                  ,
--              ATTRIBUTE19                  ,
--              ATTRIBUTE20                  ,
--              CREATED_BY                   ,
--              CREATION_DATE                ,
--              LAST_UPDATED_BY              ,
--              LAST_UPDATE_DATE             ,
--              LAST_UPDATE_LOGIN            ,
--              REQUEST_ID                   ,
--              PROGRAM_APPLICATION_ID       ,
--              PROGRAM_UPDATE_DATE          ,
--              PROGRAM_ID
--            )
--            VALUES(
--              gn_invoice_id,
--              xx03_if_header_rec.WF_STATUS,
--              xx03_if_header_rec.SLIP_TYPE,
--              gn_invoice_id,
--              xx03_if_header_rec.ENTRY_DATE,
--              NULL,
--              xx03_if_header_rec.REQUESTOR_PERSON_ID,
--              xx03_if_header_rec.REQUESTOR_PERSON_NAME,
--              xx03_if_header_rec.APPROVER_PERSON_ID,
--              xx03_if_header_rec.APPROVER_PERSON_NAME,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              0,
--              NULL,
--              'N',
--              'N',
--              xx03_if_header_rec.INVOICE_DATE,
--              xx03_if_header_rec.VENDOR_ID,
--              xx03_if_header_rec.VENDOR_NAME,
--              xx03_if_header_rec.VENDOR_SITE_ID,
--              xx03_if_header_rec.VENDOR_SITE_NAME,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              xx03_if_header_rec.INVOICE_CURRENCY_CODE,
--              xx03_if_header_rec.EXCHANGE_RATE,
--              xx03_if_header_rec.EXCHANGE_RATE_TYPE,
--              xx03_if_header_rec.EXCHANGE_RATE_TYPE_NAME,
--              xx03_if_header_rec.TERMS_ID,
--              xx03_if_header_rec.TERMS_NAME,
--              xx03_if_header_rec.DESCRIPTION,
--              xx03_if_header_rec.VENDOR_INVOICE_NUM,
--              xx03_if_header_rec.ENTRY_DEPARTMENT,
--              xx03_if_header_rec.ENTRY_PERSON_ID,
--              NULL,
--              'N',
--              xx03_if_header_rec.PAY_GROUP_LOOKUP_CODE,
--              xx03_if_header_rec.PAY_GROUP_LOOKUP_NAME,
--              xx03_if_header_rec.GL_DATE,
--              NULL,
--              xx03_if_header_rec.AUTO_TAX_CALC_FLAG,
--              xx03_if_header_rec.AP_TAX_ROUNDING_RULE,
--              xx03_if_header_rec.PREPAY_NUM,
--              ld_terms_date,
--              NULL,
-- -- 2005/04/05 Ver11.5.10.1.0 ADD Start
--              'N',
-- -- 2005/04/05 Ver11.5.10.1.0 ADD End
--              xx03_if_header_rec.ORG_ID,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              xx00_global_pkg.user_id,
--              xx00_date_pkg.get_system_datetime_f,
--              xx00_global_pkg.user_id,
--              xx00_date_pkg.get_system_datetime_f,
--              xx00_global_pkg.login_id,
--              xx00_global_pkg.conc_request_id,
--              xx00_global_pkg.prog_appl_id,
--              xx00_date_pkg.get_system_datetime_f,
--              xx00_global_pkg.conc_program_id
--            );
----
--            -- ===============================
--            -- ���׃f�[�^�R�s�[
--            -- ===============================
--            copy_detail_data(
--              iv_source,         -- �\�[�X
--              in_request_id,     -- �v��ID
--              lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
--              lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
--              lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--              RAISE global_process_expt;
--            END IF;
----
--            -- ===============================
--            -- ���z�v�Z(E-3)
--            -- ===============================
--            calc_amount(
--              lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
--              lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
--              lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--              RAISE global_process_expt;
--            END IF;
----
--            -- ===============================
--            -- �d�_�Ǘ��`�F�b�N(E-5)
--            -- ===============================
--            xx03_deptinput_ap_check_pkg.set_account_approval_flag(
--              gn_invoice_id,
--              lv_app_upd,
--              lv_errbuf,
--              lv_retcode,
--              lv_errmsg
--            );
--            IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
---- 20050217 V1.2 START
---- �����ǉ��yORG_ID�z
--              -- ���ʂ�����Ȃ�A�w�b�_���R�[�h�̏d�_�Ǘ��t���O���X�V
--              UPDATE XX03_PAYMENT_SLIPS xps
--                 SET xps.ACCOUNT_APPROVAL_FLAG = lv_app_upd
--               WHERE xps.INVOICE_ID = gn_invoice_id
--                 AND xps.ORG_ID = gn_org_id;
---- 20050217 V1.2 END
--            ELSE
--              -- ���ʂ�����łȂ���΁A�G���[���b�Z�[�W���o��
--              -- �X�e�[�^�X�����݂̒l���X�ɏ�ʂ̒l�̎��͏㏑��
--              IF ( TO_NUMBER(lv_retcode) > TO_NUMBER(gv_result)  ) THEN
--                gv_result := lv_retcode;
--              END IF;
--              -- �G���[�������Z
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03',
--                  'APP-XX03-14143'
--                )
--              );
--            END IF;
----
--            -- ===============================
--            -- �d��`�F�b�N(E-6)
--            -- ===============================
--            xx03_deptinput_ap_check_pkg. check_deptinput_ap (
--              gn_invoice_id,
--              ln_error_cnt,
--              lv_error_flg,
--              lv_error_flg1,
--              lv_error_msg1,
--              lv_error_flg2,
--              lv_error_msg2,
--              lv_error_flg3,
--              lv_error_msg3,
--              lv_error_flg4,
--              lv_error_msg4,
--              lv_error_flg5,
--              lv_error_msg5,
--              lv_error_flg6,
--              lv_error_msg6,
--              lv_error_flg7,
--              lv_error_msg7,
--              lv_error_flg8,
--              lv_error_msg8,
--              lv_error_flg9,
--              lv_error_msg9,
--              lv_error_flg10,
--              lv_error_msg10,
--              lv_error_flg11,
--              lv_error_msg11,
--              lv_error_flg12,
--              lv_error_msg12,
--              lv_error_flg13,
--              lv_error_msg13,
--              lv_error_flg14,
--              lv_error_msg14,
--              lv_error_flg15,
--              lv_error_msg15,
--              lv_error_flg16,
--              lv_error_msg16,
--              lv_error_flg17,
--              lv_error_msg17,
--              lv_error_flg18,
--              lv_error_msg18,
--              lv_error_flg19,
--              lv_error_msg19,
--              lv_error_flg20,
--              lv_error_msg20,
--              lv_errbuf,
--              lv_retcode,
--              lv_errmsg
--            );
--            IF ( ln_error_cnt > 0 ) THEN
--              -- �X�e�[�^�X�����݂̒l���X�ɏ�ʂ̒l�̎��͏㏑��
--              IF ( gv_result = cv_result_normal AND lv_error_flg = cv_dept_warning ) THEN
--                gv_result := cv_result_warning;
--              ELSIF ( lv_error_flg = cv_dept_error ) THEN
--                gv_result := cv_result_error;
--              END IF;
--              -- �d��G���[�L�莞�́A���݂��镪�S�ăG���[���b�Z�[�W���o��
--              IF ( lv_error_flg1 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg1
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg2 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg2
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg3 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg3
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg4 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg4
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg5 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg5
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg6 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg6
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg7 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg7
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg8 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg8
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg9 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg9
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg10 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg10
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg11 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg11
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg12 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg12
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg13 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg13
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg14 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg14
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg15 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg15
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg16 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg16
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg17 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg17
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg18 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg18
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg19 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg19
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg20 <> cv_dept_normal ) THEN
--                -- �G���[�������Z
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg20
--                  )
--                );
--              END IF;
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
    id_terms_date IN  DATE,         --  3.�x���\���
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
    -- ������ID�擾
    SELECT XX03_PAYMENT_SLIPS_S.nextval
      INTO gn_invoice_id
      FROM dual;
--
    -- �C���^�[�t�F�[�X�e�[�u��������ID�X�V
    UPDATE XX03_PAYMENT_SLIPS_IF xpsi
       SET INVOICE_ID = gn_invoice_id
     WHERE xpsi.REQUEST_ID = in_request_id
       AND xpsi.SOURCE = iv_source
       AND xpsi.INTERFACE_ID = xx03_if_head_line_rec.HEAD_INTERFACE_ID;
--
    -- �w�b�_�f�[�^�ۑ�
    INSERT INTO XX03_PAYMENT_SLIPS(
      INVOICE_ID                   ,
      WF_STATUS                    ,
      SLIP_TYPE                    ,
      INVOICE_NUM                  ,
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
      AP_FORWORD_DATE              ,
      RECOGNITION_CLASS            ,
      APPROVER_COMMENTS            ,
      REQUEST_ENABLE_FLAG          ,
      ACCOUNT_REVISION_FLAG        ,
      INVOICE_DATE                 ,
      VENDOR_ID                    ,
      VENDOR_NAME                  ,
      VENDOR_SITE_ID               ,
      VENDOR_SITE_NAME             ,
      INV_AMOUNT                   ,
      INV_ACCOUNTED_AMOUNT         ,
      INV_ITEM_AMOUNT              ,
      INV_TAX_AMOUNT               ,
      INV_PREPAY_AMOUNT            ,
      INVOICE_CURRENCY_CODE        ,
      EXCHANGE_RATE                ,
      EXCHANGE_RATE_TYPE           ,
      EXCHANGE_RATE_TYPE_NAME      ,
      TERMS_ID                     ,
      TERMS_NAME                   ,
      DESCRIPTION                  ,
      VENDOR_INVOICE_NUM           ,
      ENTRY_DEPARTMENT             ,
      ENTRY_PERSON_ID              ,
      ORIG_INVOICE_NUM             ,
      ACCOUNT_APPROVAL_FLAG        ,
      PAY_GROUP_LOOKUP_CODE        ,
      PAY_GROUP_LOOKUP_NAME        ,
      GL_DATE                      ,
      ACCTS_PAY_CODE_COMBINATION_ID,
      AUTO_TAX_CALC_FLAG           ,
      AP_TAX_ROUNDING_RULE         ,
      PREPAY_NUM                   ,
      TERMS_DATE                   ,
      FORM_SELECT_FLAG             ,
      DELETE_FLAG                  ,
      ORG_ID                       ,
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
      ATTRIBUTE16                  ,
      ATTRIBUTE17                  ,
      ATTRIBUTE18                  ,
      ATTRIBUTE19                  ,
      ATTRIBUTE20                  ,
-- ver 11.5.10.2.11 Add Start
      INVOICE_ELE_DATA_YES         ,
      INVOICE_ELE_DATA_NO          ,
-- ver 11.5.10.2.11 Add End
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
      gn_invoice_id,
      xx03_if_head_line_rec.HEAD_WF_STATUS,
      xx03_if_head_line_rec.HEAD_SLIP_TYPE,
      gn_invoice_id,
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
      xx03_if_head_line_rec.HEAD_INVOICE_DATE,
      xx03_if_head_line_rec.HEAD_VENDOR_ID,
      xx03_if_head_line_rec.HEAD_VENDOR_NAME,
      xx03_if_head_line_rec.HEAD_VENDOR_SITE_ID,
      xx03_if_head_line_rec.HEAD_VENDOR_SITE_NAME,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE_NAME,
      xx03_if_head_line_rec.HEAD_TERMS_ID,
      xx03_if_head_line_rec.HEAD_TERMS_NAME,
      xx03_if_head_line_rec.HEAD_DESCRIPTION,
      xx03_if_head_line_rec.HEAD_VENDOR_INVOICE_NUM,
      xx03_if_head_line_rec.HEAD_ENTRY_DEPARTMENT,
      xx03_if_head_line_rec.HEAD_ENTRY_PERSON_ID,
      NULL,
      'N',
      xx03_if_head_line_rec.HEAD_PAY_GROUP_LOOKUP_CODE,
      xx03_if_head_line_rec.HEAD_PAY_GROUP_LOOKUP_NAME,
      xx03_if_head_line_rec.HEAD_GL_DATE,
      NULL,
      xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG,
      xx03_if_head_line_rec.HEAD_AP_TAX_ROUNDING_RULE,
      xx03_if_head_line_rec.HEAD_PREPAY_NUM,
      id_terms_date,
      NULL,
      'N',
      xx03_if_head_line_rec.HEAD_ORG_ID,
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
      NULL,
      NULL,
      NULL,
      NULL,
-- ver 11.5.10.2.11 Add Start
      xx03_if_head_line_rec.HEAD_INVOICE_ELE_DATA_YES,
      xx03_if_head_line_rec.HEAD_INVOICE_ELE_DATA_NO,
-- ver 11.5.10.2.11 Add End
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
    iv_source     IN  VARCHAR2,     --  1.�\�[�X
    in_request_id IN  NUMBER,       --  2.�v��ID
    in_line_count IN  NUMBER,       --  3.���׍s��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_amount         NUMBER;          -- ���z
    lv_slip_type_name VARCHAR2(4000);  -- �E�v����
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
    -- ����ID�擾
    SELECT XX03_PAYMENT_SLIP_LINES_S.nextval
    INTO   ln_line_id
    FROM   dual;
--
    -- ver 11.5.10.2.6 Del Start
    ---- �E�v���̎擾
    --BEGIN
    --  SELECT xsltv.LOOKUP_CODE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || xsltv.DESCRIPTION as SLIP_LINE_TYPE_NAME
    --  INTO   lv_slip_type_name
    --  FROM   XX03_SLIP_LINE_TYPES_V xsltv
    --  WHERE  XSLTV.ENABLED_FLAG = 'Y'
    --    AND  xsltv.LOOKUP_CODE  = xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE
    --  ;
    --EXCEPTION
    --  WHEN NO_DATA_FOUND THEN
    --    -- �Ώۃf�[�^�Ȃ����͓E�v���̋�
    --    lv_slip_type_name := '';
    --    -- �X�e�[�^�X���G���[��
    --    gv_result := cv_result_error;
    --    -- �G���[�������Z
    --    gn_error_count := gn_error_count + 1;
    --    xx00_file_pkg.output(
    --      xx00_message_pkg.get_msg(
    --        'XX03',
    --        'APP-XX03-08026'
    --      )
    --    );
    --END;
    -- ver 11.5.10.2.6 Del End
--
    -- ���z�Z�o
    IF ( xx03_if_head_line_rec.LINE_AMOUNT_INCLUDES_TAX_FLAG = cv_yes ) THEN
      -- '����'��'Y'�̎��͋��z��'�{�̋��z+����Ŋz'
      ln_amount :=  xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT
                  + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT;
    ELSIF  ( xx03_if_head_line_rec.LINE_AMOUNT_INCLUDES_TAX_FLAG = cv_no ) THEN
      -- '����'��'N'�̎��͋��z��'�{�̋��z'
      ln_amount := xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT;
    ELSE
      -- ����ȊO�̎��͓��œ��͒l�G���[
      ln_amount := 0;
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
--
    -- ���׃f�[�^�ۑ�
    INSERT INTO XX03_PAYMENT_SLIP_LINES(
      INVOICE_LINE_ID           ,
      INVOICE_ID                ,
      LINE_NUMBER               ,
      SLIP_LINE_TYPE            ,
      SLIP_LINE_TYPE_NAME       ,
      ENTERED_AMOUNT            ,
      ENTERED_ITEM_AMOUNT       ,
      ENTERED_TAX_AMOUNT        ,
      DESCRIPTION               ,
      AMOUNT_INCLUDES_TAX_FLAG  ,
      TAX_CODE                  ,
      TAX_NAME                  ,
      SEGMENT1                  ,
      SEGMENT2                  ,
      SEGMENT3                  ,
      SEGMENT4                  ,
      SEGMENT5                  ,
      SEGMENT6                  ,
      SEGMENT7                  ,
      SEGMENT8                  ,
      SEGMENT9                  ,
      SEGMENT10                 ,
      SEGMENT11                 ,
      SEGMENT12                 ,
      SEGMENT13                 ,
      SEGMENT14                 ,
      SEGMENT15                 ,
      SEGMENT16                 ,
      SEGMENT17                 ,
      SEGMENT18                 ,
      SEGMENT19                 ,
      SEGMENT20                 ,
      SEGMENT1_NAME             ,
      SEGMENT2_NAME             ,
      SEGMENT3_NAME             ,
      SEGMENT4_NAME             ,
      SEGMENT5_NAME             ,
      SEGMENT6_NAME             ,
      SEGMENT7_NAME             ,
      SEGMENT8_NAME             ,
      INCR_DECR_REASON_CODE     ,
      INCR_DECR_REASON_NAME     ,
      RECON_REFERENCE           ,
      ORG_ID                    ,
      ATTRIBUTE_CATEGORY        ,
      ATTRIBUTE1                ,
      ATTRIBUTE2                ,
      ATTRIBUTE3                ,
      ATTRIBUTE4                ,
      ATTRIBUTE5                ,
      ATTRIBUTE6                ,
      ATTRIBUTE7                ,
      ATTRIBUTE8                ,
      ATTRIBUTE9                ,
      ATTRIBUTE10               ,
      ATTRIBUTE11               ,
      ATTRIBUTE12               ,
      ATTRIBUTE13               ,
      ATTRIBUTE14               ,
      ATTRIBUTE15               ,
      CREATED_BY                ,
      CREATION_DATE             ,
      LAST_UPDATED_BY           ,
      LAST_UPDATE_DATE          ,
      LAST_UPDATE_LOGIN         ,
      REQUEST_ID                ,
      PROGRAM_APPLICATION_ID    ,
      PROGRAM_ID                ,
      PROGRAM_UPDATE_DATE
    )
    VALUES(
      ln_line_id,
      gn_invoice_id,
      in_line_count,
      xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE,
      -- ver 11.5.10.2.6 Chg Start
      --lv_slip_type_name,
      xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE_NAME,
      -- ver 11.5.10.2.6 Chg End
      ln_amount,
      xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT,
      xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT,
      xx03_if_head_line_rec.LINE_DESCRIPTION,
      xx03_if_head_line_rec.LINE_AMOUNT_INCLUDES_TAX_FLAG,
      xx03_if_head_line_rec.LINE_TAX_CODE,
      xx03_if_head_line_rec.LINE_TAX_NAME,
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
-- ver 11.5.10.2.10H Mod Start
--      NULL,
      xx03_if_head_line_rec.LINE_ORG_ID,
-- ver 11.5.10.2.10H Mod End
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
-- ver 11.5.10.2.10H Mod Start
--      NULL,
      xx03_if_head_line_rec.LINE_ATTRIBUTE7,
-- ver 11.5.10.2.10H Mod End
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
      xx00_global_pkg.conc_program_id,
      xx00_date_pkg.get_system_datetime_f
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
  END ins_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : check_header_data
   * Description      : �������f�[�^�̓��̓`�F�b�N(E-2)
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
-- ver 11.5.10.2.10E Del Start
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
-- ver 11.5.10.2.10E Del End
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
-- ver 11.5.10.2.10E Chg Start
----      -- ���F�Җ������͂���Ă���ꍇ�͏��F�r���[�ɂčă`�F�b�N
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
        xx00_file_pkg.output(xx00_message_pkg.get_msg('XX03','APP-XX03-08011'));
      END IF;
-- ver 11.5.10.2.10E Chg End
-- Ver11.5.10.1.5B Add End
    END IF;
--
    -- �d����`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_VENDOR_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_VENDOR_ID) = '' ) THEN
      -- �d����ID����̏ꍇ�͎d������̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08012'
        )
      );
    END IF;
--
    -- �d����T�C�g�`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_VENDOR_SITE_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_VENDOR_SITE_ID) = '' ) THEN
      -- �d����T�C�gID����̏ꍇ�͎d����T�C�g���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08013'
        )
      );
    END IF;
--
    -- ver 11.5.10.2.6 Add Start
    -- �U��������`�F�b�N
    -- ver 11.5.10.2.10D Chg Start
    --IF      ( xx03_if_head_line_rec.HEAD_VENDOR_PAYMETHOD = cv_paymethod_eft
    IF      ( xx03_if_head_line_rec.HEAD_PAY_GROUP_PAYMETHOD = cv_paymethod_eft
    -- ver 11.5.10.2.10D Chg End
        AND ( xx03_if_head_line_rec.HEAD_VENDOR_BANK_NAME IS NULL
                OR TRIM(xx03_if_head_line_rec.HEAD_VENDOR_BANK_NAME) = '' )) THEN
      -- �d����T�C�g�x�����@���d�M�ŐU�����������̏ꍇ�͐U����������̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          -- ver 11.5.10.2.10D Chg Start
          --'APP-XX03-12509' ,
          'APP-XX03-12516' ,
          -- ver 11.5.10.2.10D Chg End
          'SLIP_NUM' ,''
        )
      );
    END IF;
    -- ver 11.5.10.2.6 Add End
--
    -- ���������t�`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_INVOICE_DATE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_INVOICE_DATE) = '' ) THEN
      -- ���������t����̏ꍇ�͐��������t���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08014'
        )
      );
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
    -- �x���O���[�v�`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_PAY_GROUP_LOOKUP_CODE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_PAY_GROUP_LOOKUP_CODE) = '' ) THEN
      -- �x���O���[�v����̏ꍇ�͎x���O���[�v���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08016'
        )
      );
    END IF;
--
    -- �x�������`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_TERMS_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_TERMS_ID) = '' ) THEN
      -- �x������ID����̏ꍇ�͎x���������̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08017'
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
    -- �x�������A�x���\����֘A���`�F�b�N
    IF (( xx03_if_head_line_rec.HEAD_TERMS_CHANGE_FLG = cv_yes
          AND ( xx03_if_head_line_rec.HEAD_TERMS_DATE IS NULL
                OR TRIM(xx03_if_head_line_rec.HEAD_TERMS_DATE) = ''))
        OR ( xx03_if_head_line_rec.HEAD_TERMS_CHANGE_FLG = cv_no
          AND ( xx03_if_head_line_rec.HEAD_TERMS_DATE IS NOT NULL
                OR TRIM(xx03_if_head_line_rec.HEAD_TERMS_DATE) <> ''))) THEN
      -- �x���\����ύX�s�œ��͂���A�������͎x���\����ύX�œ��͂Ȃ��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08019'
        )
      );
    END IF;
--
    -- �O�����[���`�[�ԍ��`�F�b�N
    IF (xx03_if_head_line_rec.HEAD_PREPAY_NUM IS NOT NULL
        AND (xx03_if_head_line_rec.HEAD_PREPAY_INVOICE_NUM IS NULL
             OR TRIM(xx03_if_head_line_rec.HEAD_PREPAY_INVOICE_NUM) = '' )) THEN
      -- �O�����[���`�[����i�擾�ł��Ȃ��j�ꍇ�͓��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14057'
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
  /**********************************************************************************
   * Procedure Name   : check_detail_data
   * Description      : �������f�[�^�̓��̓`�F�b�N(E-2)
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
--
    -- ver 11.5.10.1.6F Add Start
    -- �E�v�R�[�h�`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE_NAME) = '' ) THEN
      -- �E�v�R�[�h������̏ꍇ�͓E�v�R�[�h���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08026'
        )
      );
    END IF;
--
    -- �ŋ敪�`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_TAX_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_TAX_NAME) = '' ) THEN
      -- �ŋ敪����̏ꍇ�͐ŋ敪���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08035'
        )
      );
    END IF;
    -- ver 11.5.10.1.6F Add End
--
-- Ver11.5.10.1.6E Add Start
    -- ��Ѓ`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT1 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT1) = '' ) THEN
      -- ��Ђ���̏ꍇ�͉�Г��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08036'
        )
      );
    END IF;
--
    -- ����`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT2 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT2) = '' ) THEN
      -- ���傪��̏ꍇ�͕�����̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08037'
        )
      );
    END IF;
--
    -- ����Ȗڃ`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT3 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT3) = '' ) THEN
      -- ����Ȗڂ���������͕s���̏ꍇ�͊���Ȗړ��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08038'
        )
      );
  END IF;
--
    -- �⏕�Ȗڃ`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT4 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT4) = '' ) THEN
      -- ����Ȗڂ���̏ꍇ�͊���Ȗړ��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08039'
        )
      );
    END IF;
--
    -- �����`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT5 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT5) = '' ) THEN
      -- ����悪��̏ꍇ�͑������̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08040'
        )
      );
    END IF;
--
    -- ���Ƌ敪�`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT6 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT6) = '' ) THEN
      -- ���Ƌ敪����̏ꍇ�͎��Ƌ敪���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08041'
        )
      );
    END IF;
--
    -- �v���W�F�N�g�`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT7 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT7) = '' ) THEN
      -- �v���W�F�N�g����̏ꍇ�̓v���W�F�N�g���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08042'
        )
      );
    END IF;
--
    -- �\���`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SEGMENT8 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT8) = '' ) THEN
      -- �\������̏ꍇ�͗\�����̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08043'
        )
      );
    END IF;
-- Ver11.5.10.1.6E Add End
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
    in_total_item_amount IN  NUMBER,       --  1.���v�{�̋��z
    in_total_tax_amount  IN  NUMBER,       --  2.���v�ŋ����z
    in_prepay_amount     IN  NUMBER,       --  3.�O���[�����z
    iv_cur_code          IN  VARCHAR2,     --  4.�ʉ݃R�[�h
    in_exchange_rate     IN  NUMBER,       --  5.���Z���[�g
    ov_errbuf            OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode           OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
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
    lv_app_upd          VARCHAR2(1);         -- �d�_�Ǘ��t���O
    ln_accounted_amount NUMBER;
--
    ln_error_cnt   NUMBER;          -- �d��`�F�b�N�G���[����
    lv_error_flg   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O
    lv_error_flg1  VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O1
    lv_error_msg1  VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W1
    lv_error_flg2  VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O2
    lv_error_msg2  VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W2
    lv_error_flg3  VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O3
    lv_error_msg3  VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W3
    lv_error_flg4  VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O4
    lv_error_msg4  VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W4
    lv_error_flg5  VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O5
    lv_error_msg5  VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W5
    lv_error_flg6  VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O6
    lv_error_msg6  VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W6
    lv_error_flg7  VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O7
    lv_error_msg7  VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W7
    lv_error_flg8  VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O8
    lv_error_msg8  VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W8
    lv_error_flg9  VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O9
    lv_error_msg9  VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W9
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
--
    --�ʉ݃R�[�h���@�\�ʉ݂łȂ��ꍇ�͎x�����z�����[�g���Z���Ċ��Z�ύ��v���z�Z�b�g
    ln_accounted_amount := (in_total_item_amount + in_total_tax_amount) - in_prepay_amount;
    IF ( iv_cur_code != gv_cur_code ) THEN
      SELECT TO_NUMBER( TO_CHAR( ln_accounted_amount * in_exchange_rate
                                ,xx00_currency_pkg.get_format_mask(gv_cur_code, 38))
                       ,xx00_currency_pkg.get_format_mask(gv_cur_code, 38))
      INTO   ln_accounted_amount
      FROM   dual;
    END IF;
--
    -- �w�b�_���z�X�V
    UPDATE XX03_PAYMENT_SLIPS xps
    SET    xps.INV_ITEM_AMOUNT      = in_total_item_amount
         , xps.INV_TAX_AMOUNT       = in_total_tax_amount
         , xps.INV_AMOUNT           = (in_total_item_amount + in_total_tax_amount) - in_prepay_amount
         , xps.INV_ACCOUNTED_AMOUNT = ln_accounted_amount
    WHERE  xps.INVOICE_ID = gn_invoice_id
      AND  xps.ORG_ID     = gn_org_id;
--
    -- �d�_�Ǘ��`�F�b�N
    xx03_deptinput_ap_check_pkg.set_account_approval_flag(
      gn_invoice_id,
      lv_app_upd,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
    IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      -- ���ʂ�����Ȃ�A�w�b�_���R�[�h�̏d�_�Ǘ��t���O���X�V
      UPDATE XX03_PAYMENT_SLIPS xps
      SET    xps.ACCOUNT_APPROVAL_FLAG = lv_app_upd
      WHERE  xps.INVOICE_ID = gn_invoice_id
        AND  xps.ORG_ID = gn_org_id;
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
    xx03_deptinput_ap_check_pkg.check_deptinput_ap(
      gn_invoice_id,
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
   * Description      : �C���^�[�t�F�[�X�f�[�^�̃R�s�[
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
    ln_max_line          NUMBER := xx00_profile_pkg.value('VO_MAX_FETCH_SIZE'); -- �ő喾�׍s��
    lv_max_over_flg      VARCHAR2(1);   -- �ő喾�׍s�I�[�o�[�t���O
    ln_interface_id      NUMBER;        -- INTERFACE_ID
    ln_if_id_back        NUMBER;        -- INTERFACE_ID�O���R�[�h�d���`�F�b�N
    lv_if_id_new_flg     VARCHAR2(1);   -- INTERFACE_ID�ύX�t���O
    lv_first_flg         VARCHAR2(1);   -- �������R�[�h�t���O
    ln_total_item_amount NUMBER;        -- �{�̋��z���v
    ln_total_tax_amount  NUMBER;        -- �{�̐ŋ����v
    ln_prepay_amount     NUMBER;        -- �O���[����
    lv_cur_code          VARCHAR2(15);  -- �ʉ݃R�[�h
    ln_exchange_rate     NUMBER;        -- ���Z���[�g
    ln_line_count        NUMBER;        -- ���׌����J�E���g
    ld_terms_date        DATE;          -- �x���\���
    lv_terms_flg         VARCHAR2(1);   -- �x���\����ύX�\�t���O
--
    -- ver 11.5.10.1.6F Add Start
    lv_first_tax_code    VARCHAR2(15);  -- �P���זڂ̐ŋ��R�[�h
    lb_chk_tax_code      BOOLEAN;       -- �ŋ��R�[�h��v�`�F�b�N�p
    -- ver 11.5.10.1.6F Add End
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
    -- �������R�[�h�t���O
    lv_first_flg      := '1';
    ln_if_id_back     := -1;
--
    -- �w�b�_���׏��J�[�\���I�[�v��
    OPEN xx03_if_head_line_cur(iv_source, in_request_id);
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
              ln_total_item_amount, --  1.�{�̍��v���z
              ln_total_tax_amount,  --  2.�ŋ����v���z
              ln_prepay_amount,     --  3.�O���[�����z
              lv_cur_code,          --  4.�ʉ݃R�[�h
              ln_exchange_rate,     --  5.���Z���[�g
              lv_errbuf,            --  �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,           --  ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
        ln_total_item_amount := 0;
        ln_total_tax_amount  := 0;
--
        -- ���טA�ԏ�����
        ln_line_count  := 1;
--
        -- �G���[����������
        gn_error_count := 0;
--
        -- ver 11.5.10.1.6F Add Start
        -- �`�[�̂P���R�[�h�ڂ̖��ׂ̐ŋ敪��ۑ�
        -- �Ōv�Z���x���`�F�b�N�Ɏg�p
        lv_first_tax_code := xx03_if_head_line_rec.LINE_TAX_CODE;
        lb_chk_tax_code   := true;
        -- ver 11.5.10.1.6F Add End
--
      END IF;
--
      -- INTERFACE_ID����l�w�b�_���P����葽�����̓w�b�_�G���[
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
            -- ===============================
            -- �x���\����擾(E-4)
            -- ===============================
            xx03_deptinput_ap_check_pkg.get_terms_date(
              xx03_if_head_line_rec.HEAD_TERMS_ID,
              xx03_if_head_line_rec.HEAD_INVOICE_DATE,
              xx03_if_head_line_rec.HEAD_TERMS_DATE,
              ld_terms_date,
              lv_terms_flg,
              lv_errbuf,
              lv_retcode,
              lv_errmsg
            );
--
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
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
                  'APP-XX03-14101',
                  'TOK_XX03_CHECK_ERROR',
                  lv_errmsg
                )
              );
            END IF;
--
          END IF;
--
          -- �G���[�����o����Ă��Ȃ����݈̂ȍ~�̏������s
          IF ( gn_error_count = 0 ) THEN
            -- �w�b�_�e�[�u���֑}��
            ins_header_data(
              iv_source,         -- �\�[�X
              in_request_id,     -- �v��ID
              ld_terms_date,     -- �x���\���
              lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #

            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
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
        -- ver 11.5.10.1.6F Add Start
        -- ����Ōv�Z���x�����w�b�_�̏ꍇ���ׂ̐ŋ敪��v���K�v
        IF xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG = 'Y' THEN
          -- �`�[�̂P���R�[�h�ڂ̖��ׂ̐ŋ敪�Ɣ�r
          IF lv_first_tax_code != xx03_if_head_line_rec.LINE_TAX_CODE AND lb_chk_tax_code = true THEN
            -- �X�e�[�^�X���G���[��
            lb_chk_tax_code := false;
            gv_result := cv_result_error;
            -- �G���[�������Z
            gn_error_count := gn_error_count + 1;
            xx00_file_pkg.output(xx00_message_pkg.get_msg('XX03','APP-XX03-12512'));
          END IF;
        END IF;
        -- ver 11.5.10.1.6F Add End
--
        -- �G���[�����o����Ă��Ȃ����݈̂ȍ~�̏������s
        IF ( gn_error_count = 0 ) THEN
          -- ���׃e�[�u���֑}��
          ins_detail_data(
            iv_source,         -- �\�[�X
            in_request_id,     -- �v��ID
            ln_line_count,     -- ���׍s��
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ���v���z�Z�o�p�ϐ����Z
        ln_total_item_amount := ln_total_item_amount + xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT;
        ln_total_tax_amount  := ln_total_tax_amount  + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT;
--
        -- �[�����z�v�Z
        IF ( xx03_if_head_line_rec.HEAD_PREPAY_NUM IS NOT NULL ) THEN
          -- ���R�[�h�̏[�����z�ƁA�{�̋��z�{����Ŋz�̏����������[�����z�Ƃ���
          IF ( nvl(xx03_if_head_line_rec.HEAD_PREPAY_AMOUNT_APPLIED,0) > (ln_total_item_amount + ln_total_tax_amount)) THEN
            ln_prepay_amount := ln_total_item_amount + ln_total_tax_amount;
          ELSE
            ln_prepay_amount := nvl(xx03_if_head_line_rec.HEAD_PREPAY_AMOUNT_APPLIED,0);
          END IF;
        ELSE
          -- �[���`�[�Ȃ�
          ln_prepay_amount := 0;
        END IF;
--
        -- �ʉ݃R�[�h�E���Z���[�g
        lv_cur_code      := xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE;
        ln_exchange_rate := xx03_if_head_line_rec.HEAD_EXCHANGE_RATE;
--
        -- ���׍ő�s���`�F�b�N
        IF ln_line_count > ln_max_line THEN
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
--
        -- ���טA�ԉ��Z
        ln_line_count := ln_line_count + 1;
--
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
          ln_total_item_amount, --  1.�{�̍��v���z
          ln_total_tax_amount,  --  2.�ŋ����v���z
          ln_prepay_amount,     --  3.�O���[�����z
          lv_cur_code,          --  4.�ʉ݃R�[�h
          ln_exchange_rate,     --  5.���Z���[�g
          lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
-- Ver11.5.10.1.5 2005/09/05 Change End
--
  /**********************************************************************************
   * Procedure Name   : update_slip_number
   * Description      : �������ԍ��Ǘ��e�[�u���̍X�V
   ***********************************************************************************/
  PROCEDURE update_slip_number(
    in_add_count    IN  NUMBER,       -- 1.�X�V����
    ov_slip_code    OUT VARCHAR2,     -- 2.�������R�[�h
    on_slip_number  OUT NUMBER,       -- 3.�������ԍ�
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
-- 20050217 V1.2 START
-- �����ǉ��yORG_ID�z
    -- ���݂̐������ԍ��擾
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --SELECT xsn.TEMPORARY_CODE,
    --       xsn.SLIP_NUMBER
    --  INTO lv_slip_code,
    --       ln_slip_number
    --  FROM XX03_SLIP_NUMBERS xsn
    -- WHERE xsn.APPLICATION_SHORT_NAME = 'SQLAP'
    --   AND xsn.NUM_TYPE = '0'
    --   AND xsn.ORG_ID = gn_org_id
    --FOR UPDATE NOWAIT;
    SELECT xsn.TEMPORARY_CODE,
           xsn.SLIP_NUMBER
      INTO lv_slip_code,
           ln_slip_number
      FROM XX03_SLIP_NUMBERS xsn
     WHERE xsn.APPLICATION_SHORT_NAME = 'SQLAP'
       AND xsn.NUM_TYPE = '0'
       AND xsn.ORG_ID = xx00_profile_pkg.value('ORG_ID')
    FOR UPDATE NOWAIT;
    -- Ver11.5.10.1.6D 2006/01/06 Change End
-- 20050217 V1.2 END
--
    -- �������ԍ����Z
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --UPDATE XX03_SLIP_NUMBERS xsn
    --   SET xsn.SLIP_NUMBER = ln_slip_number + in_add_count
    -- WHERE xsn.APPLICATION_SHORT_NAME = 'SQLAP'
    --   AND xsn.NUM_TYPE = '0';
    UPDATE XX03_SLIP_NUMBERS xsn
       SET xsn.SLIP_NUMBER = ln_slip_number + in_add_count
     WHERE xsn.APPLICATION_SHORT_NAME = 'SQLAP'
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
    -- ver 11.5.10.2.10I Add Start
    cv_slip_code CONSTANT VARCHAR2(3) := 'TMP';
    -- ver 11.5.10.2.10I Add End
--
    -- *** ���[�J���ϐ� ***
    ln_update_count NUMBER;     -- �X�V����
-- ver 11.5.10.2.10I Del Start
--    lv_slip_code VARCHAR2(10);  -- �������R�[�h
--    ln_slip_number NUMBER;      -- �������ԍ�
-- ver 11.5.10.2.10I Del Start
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �X�V�Ώێ擾�J�[�\��
    CURSOR update_record_cur
    IS
      SELECT xps.INVOICE_ID
        FROM XX03_PAYMENT_SLIPS xps
       WHERE xps.REQUEST_ID = xx00_global_pkg.conc_request_id
      ORDER BY xps.INVOICE_ID;
--
    -- ���O�o�͗p�J�[�\��
    CURSOR outlog_cur(pv_source VARCHAR2,
                        pn_request_id NUMBER)
    IS
      SELECT xpsi.INTERFACE_ID as INTERFACE_ID,
             xps.INVOICE_NUM as INVOICE_NUM
        FROM XX03_PAYMENT_SLIPS_IF xpsi,
             XX03_PAYMENT_SLIPS xps
       WHERE xpsi.REQUEST_ID = pn_request_id
         AND xpsi.SOURCE = pv_source
         AND xpsi.INVOICE_ID = xps.INVOICE_ID;
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
      SELECT COUNT(xps.INVOICE_ID)
        INTO ln_update_count
        FROM XX03_PAYMENT_SLIPS xps
       WHERE xps.REQUEST_ID = xx00_global_pkg.conc_request_id;
--
-- ver 11.5.10.2.10I Del Start
--      -- �������ԍ��擾
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
-- ver 11.5.10.2.10I Del End
--
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
-- ver 11.5.10.2.10I Del Start
--        -- �������ԍ����Z
--        ln_slip_number := ln_slip_number + 1;
-- ver 11.5.10.2.10I Del Del
--
-- 20050217 V1.2 START
-- �����ǉ��yORG_ID�z
        -- �������ԍ��X�V
        UPDATE XX03_PAYMENT_SLIPS xps
-- ver 11.5.10.2.10I Mod Start
--           SET xps.INVOICE_NUM = lv_slip_code || TO_CHAR(ln_slip_number)
           SET xps.INVOICE_NUM = cv_slip_code || TO_CHAR(xxcfo_slip_number_ap_s1.NEXTVAL)
-- ver 11.5.10.2.10I Mod End
         WHERE xps.INVOICE_ID = update_record_rec.INVOICE_ID
           AND xps.ORG_ID = gn_org_id;
-- 20050217 V1.2 END
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
            outlog_rec.INVOICE_NUM
          )
        );
--
      END LOOP out_log_loop;
      CLOSE outlog_cur;
--
      -- ver 11.5.10.2.5 Del Start
      ---- �C���^�[�t�F�[�X�e�[�u���f�[�^�폜
      --DELETE FROM XX03_PAYMENT_SLIPS_IF xpsi
      --      WHERE xpsi.REQUEST_ID = in_request_id
      --        AND xpsi.SOURCE = iv_source;
      ----
      --DELETE FROM XX03_PAYMENT_SLIP_LINES_IF xpsli
      --      WHERE xpsli.REQUEST_ID = in_request_id
      --        AND xpsli.SOURCE = iv_source;
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
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = xx00_common_pkg.set_status_error_f) THEN
      ROLLBACK;
    END IF;
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
END XX034DD001C;
/
