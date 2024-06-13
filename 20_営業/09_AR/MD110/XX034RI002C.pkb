CREATE OR REPLACE PACKAGE BODY APPS.XX034RI002C
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2004-2005. All rights reserved.
 *
 * Package Name     : XX034RI002C(body)
 * Description      : �C���^�[�t�F�[�X�e�[�u������̐����˗��f�[�^�C���|�[�g
 * MD.050(CMD.040)  : ������̓o�b�`�����iAR�j       OCSJ/BFAFIN/MD050/F702
 * MD.070(CMD.050)  : ������́iAR�j�f�[�^�C���|�[�g OCSJ/BFAFIN/MD070/F702
 * Version          : 11.5.10.2.14
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
 * ------------ -------------- -----------------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -----------------------------------------------------------
 *  2005/01/12   1.0            main�V�K�쐬
 *  2005/03/02   1.1            �w�b�_�R�����g�����Q�Ɣԍ��C��
 *  2005/03/09   1.2            �s��Ή�
 *  2005/04/06   11.5.10.1.0    �s��Ή�(�x�����@�̎擾�p�������̕ύX)
 *  2005/04/25   11.5.10.1.1    �s��Ή�(�P�ʂ̃`�F�b�N�ǉ�)
 *  2005/04/27   11.5.10.1.1    �s��Ή�(�P�ʂ̃`�F�b�N�����Ή�����̂��ߏC��)
 *  2005/08/15   11.5.10.1.4    ����Ȗڎ擾��VIEW���A���{������l���������̂ɕύX
 *  2005/09/05   11.5.10.1.5    �p�t�H�[�}���X���P�Ή�
 *  2005/10/20   11.5.10.1.5B   ���F�҃r���[�Ƃ̌����s��Ή�
 *  2005/10/21   11.5.10.1.5C   ���͓��Ńt���O�ƁA�ŋ��}�X�^�[�Ŏw�肵��
 *                              �ŋ��R�[�h�̓��Ńt���O�̈�v�`�F�b�N�ǉ�
 *  2005/12/19   11.5.10.1.6    ���F�҂̔��f��̏C���Ή�
 *  2005/12/27   11.5.10.1.6B   �ŃR�[�h���v����œ��t�`�F�b�N���������ǉ�
 *  2005/12/28   11.5.10.1.6C   �`�[��ʂɃA�v���P�[�V�������̍i���݂�ǉ�
 *  2006/01/06   11.5.10.1.6D   �`�[�ԍ��̍̔ԏ����ɃI���O��ǉ�
 *  2006/09/05   11.5.10.2.5    �A�b�v���[�h�����ŕ������[�U�̓������s�\�Ƃ���
 *                              ����̌��A�f�[�^�폜�����̌��C��
 *                              ���b�Z�[�W�R�[�h�̌��C��
 *  2006/09/20   11.5.10.2.5B   �������s���\�Ƃ���Ή��̍ďC��
 *  2006/10/04   11.5.10.2.6    �}�X�^�`�F�b�N�̌�����(�L�����̃`�F�b�N�𐿋������t��
 *                              �s�Ȃ����ڂ�SYSDATE�ōs�Ȃ����ڂ��Ċm�F)
 *  2006/10/27   11.5.10.2.6B   ����`�[���̖��הԍ��̏d���`�F�b�N��ǉ�
 *  2007/02/23   11.5.10.2.7    �v���O�������s���̃��[�U�E�E�ӂɕR�t�����j���[��
 *                              �o�^����Ă���`�[��ʂ��̃`�F�b�N��ǉ�
 *  2007/04/23   11.5.10.2.9    ���ׂ̖��ה��l���ڂɂ��āA���͉\Byte��30Byte�Ƃ��邽��
 *                              �Ώۍ��ڂ�Byte���`�F�b�N������ǉ�
 *  2007/06/20   11.5.10.2.9B   �������e�Ɋւ��Ẵf�[�^���o�T�u�N�G���[������Ă��邽��
 *                              �}�X�^�ɑ��݂��Ă��Ă�ID���ݒ肳��Ȃ����̏C��
 *  2007/07/17   11.5.10.2.10   �}�X�^�`�F�b�N�̒ǉ�(�w�b�_�F����^�C�v,���ׁF�������R)
 *                              �}�X�^�`�F�b�N�R�����g�̏C��(���ׁF�������e)
 *  2007/08/16   11.5.10.2.10B  ��s�x�X�̖������͑O���܂ŗL���Ƃ���悤�ɏC��
 *  2007/08/28   11.5.10.2.10C  AR�ʉݗL�����̔�r�Ώۂ͐��������t�Ƃ���C��
 *  2007/08/29   11.5.10.2.10D  AR�ʉݗL�����̔�r�Ώۂ͐��������t�Ƃ���C��
 *  2007/09/28   11.5.10.2.10E  �O��ߏ[���`�[�ԍ����ڂ̌^�̈Ⴂ���l������SQL�ɏC��
 *  2007/10/10   11.5.10.2.10F  �p�t�H�[�}���X�Ή��̂��ߏ��F�҂̃`�F�b�NSQL��
 *                              ���C��SQL�֑g�ݍ��ނ悤�ɏC��
 *  2007/12/12   11.5.10.2.10G  �P���~���ʂ̌��ʂ͒ʉݏ����Ɋۂ߂鏈����ǉ�
 *  2008/02/18   11.5.10.2.10H  ���ׂ̔[�i���ԍ����ڂɂ��āA���͉\Byte��30Byte
 *                              �Ƃ��邽�ߑΏۍ��ڂ�Byte���`�F�b�N������ǉ�
 *  2012/10/24   11.5.10.2.11   [E_�{�ғ�_09965]�p�t�H�[�}���X�Ή��̂��߁A
 *                              XX03_COMMITMENT_NUMBER_LOV_V���R�����g�A�E�g����悤�ɏC��
 *  2016/12/06   11.5.10.2.12   ��Q�Ή�E_�{�ғ�_13901
 *  2021/12/17   11.5.10.2.13   [E_�{�ғ�_17678]�Ή� �d�q����ۑ��@�����Ή�
 *  2023/11/02   11.5.10.2.14   [E_�{�ғ�_19496]�Ή� �O���[�v��Г����Ή�
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
  cv_appli_cd       CONSTANT VARCHAR2(30)  := 'AR';                      --�A�v���P�[�V�������2
  cv_package_name   CONSTANT VARCHAR2(20)  := 'XX034RI002';              --�p�b�P�[�W��
  cv_yes            CONSTANT VARCHAR2(1)   := 'Y';  --�͂�
  cv_no             CONSTANT VARCHAR2(1)   := 'N';  --������
  cv_dept_normal    CONSTANT VARCHAR2(1)   := 'S';  -- �d��`�F�b�N���ʁi����j
  cv_dept_warning   CONSTANT VARCHAR2(1)   := 'W';  -- �d��`�F�b�N���ʁi�x���j
  cv_dept_error     CONSTANT VARCHAR2(1)   := 'E';  -- �d��`�F�b�N���ʁi�G���[�j
  cv_result_normal  CONSTANT VARCHAR2(1)   := '0';  -- �I���X�e�[�^�X�i����j
  cv_result_warning CONSTANT VARCHAR2(1)   := '1';  -- �I���X�e�[�^�X�i�x���j
  cv_result_error   CONSTANT VARCHAR2(1)   := '2';  -- �I���X�e�[�^�X�i�G���[�j
--
  cv_prof_GL_ID     CONSTANT VARCHAR2(20)  := 'GL_SET_OF_BKS_ID'; -- ��v����ID�̎擾�p�L�[�l
  cv_appl_AR_ID     CONSTANT VARCHAR2(20)  := 'AR';               -- �A�v���P�[�V����ID�̎擾�p�L�[�l
--
  -- ver 11.5.10.2.7 Add Start
  cv_menu_url_inp   CONSTANT VARCHAR2(100) := 'OA.jsp?page=/oracle/apps/xx03/ar/input/webui/Xx03InvoiceInputPG';
  -- ver 11.5.10.2.7 Add End
--
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
--  gn_invoice_id     NUMBER;       -- ������ID
  gn_receivable_id  NUMBER;       -- �`�[ID
  gn_error_count    NUMBER;       -- �G���[����
  gv_result         VARCHAR2(1);  -- �`�F�b�N���ʃX�e�[�^�X
--
-- Ver11.5.10.1.5 2005/09/06 Add Start
  gv_cur_code    VARCHAR2(15);        -- �@�\�ʉ݃R�[�h
-- Ver11.5.10.1.5 2005/09/06 Add End
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
---- ver 11.5.10.1.0 Change Start
--    SELECT * FROM (
--      SELECT
--          xrsi.INTERFACE_ID            as INTERFACE_ID              -- �C���^�[�t�F�[�XID
--        , xrsi.WF_STATUS               as WF_STATUS                 -- �X�e�[�^�X
--        , xstl.LOOKUP_CODE             as SLIP_TYPE                 -- �`�[���
--        , TRUNC(xrsi.ENTRY_DATE, 'DD') as ENTRY_DATE                -- �N�[��
--        , xpp.PERSON_ID                as REQUESTOR_PERSON_ID       -- �\����
--        , xpp.EMPLOYEE_DISP            as REQUESTOR_PERSON_NAME     -- �\���Җ�
--        , xapl.PERSON_ID               as APPROVER_PERSON_ID        -- ���F��
--        , xapl.EMPLOYEE_DISP           as APPROVER_PERSON_NAME      -- ���F�Җ�
--        , xrsi.INVOICE_DATE            as INVOICE_DATE              -- ���������t
--        , xttl.CUST_TRX_TYPE_ID        as TRANS_TYPE_ID             -- ����^�C�vID
--        , xrsi.TRANS_TYPE_NAME         as TRANS_TYPE_NAME           -- ����^�C�v��
--        , xacl.CUSTOMER_ID             as CUSTOMER_ID               -- �ڋqID
--        , xacl.CUSTOMER_NAME           as CUSTOMER_NAME             -- �ڋq��
--        , xcsl.ADDRESS_ID              as CUSTOMER_OFFICE_ID        -- �ڋq���Ə�ID
--        , xrsi.LOCATION                as CUSTOMER_OFFICE_NAME      -- �ڋq���Ə���
--        , xrsi.CURRENCY_CODE           as INVOICE_CURRENCY_CODE     -- �ʉ�
--        , xrsi.CONVERSION_RATE         as CONVERSION_RATE           -- ���[�g
--        , xct.CONVERSION_TYPE          as EXCHANGE_RATE_TYPE        -- ���[�g�^�C�v
--        , xrsi.CONVERSION_TYPE         as EXCHANGE_RATE_TYPE_NAME   -- ���[�g�^�C�v��
--        , xtl.TERMSID                  as TERMS_ID                  -- �x������ID
--        , xrsi.TERMS_NAME              as TERMS_NAME                -- �x��������
--        , xrsi.DESCRIPTION             as DESCRIPTION               -- ���l
--        , xpp.ATTRIBUTE28              as ENTRY_DEPARTMENT          -- �N�[����
--        , xpp2.PERSON_ID               as ENTRY_PERSON_ID           -- �`�[���͎�
--        , xrsi.GL_DATE                 as GL_DATE                   -- �v���
--        , xrml.BATCH_SOURCE_ID         as RECEIPT_METHOD_ID         -- �x�����@ID
--        , xrsi.RECEIPT_METHOD_NAME     as RECEIPT_METHOD_NAME       -- �x�����@��
--        , xrsi.ONETIME_CUSTOMER_NAME       as ONETIME_CUSTOMER_NAME       -- �ڋq����
--        , xrsi.ONETIME_CUSTOMER_KANA_NAME  as ONETIME_CUSTOMER_KANA_NAME  -- �J�i��
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_1  as ONETIME_CUSTOMER_ADDRESS_1  -- �Z���P
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_2  as ONETIME_CUSTOMER_ADDRESS_2  -- �Z���Q
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_3  as ONETIME_CUSTOMER_ADDRESS_3  -- �Z���R
--        , xcsl.TAX_HEADER_LEVEL_FLAG   as AUTO_TAX_CALC_FLAG              -- ����Ōv�Z���x��(���Ə��P��)
--        , SUBSTRB(xcsl.TAX_ROUNDING_RULE, 1, 1)   as TAX_ROUNDING_RULE    -- ����Œ[������(���Ə��P��)
--        , xcsl.TAX_HEADER_LEVEL_FLAG_C as AUTO_TAX_CALC_FLAG_C            -- ����Ōv�Z���x��(�ڋq�P��)
--        , SUBSTRB(xcsl.TAX_ROUNDING_RULE_C, 1, 1) as TAX_ROUNDING_RULE_C  -- ����Œ[������(�ڋq�P��)
--        , xrsi.COMMITMENT_NUMBER       as COMMITMENT_NUMBER         -- �O����[���`�[�ԍ�
--        , xrsi.ORG_ID                  as ORG_ID                    -- �I���OID
--        , xrsi.CREATED_BY              as CREATED_BY
--        , xrsi.CREATION_DATE           as CREATION_DATE
--        , xrsi.LAST_UPDATED_BY         as LAST_UPDATED_BY
--        , xrsi.LAST_UPDATE_DATE        as LAST_UPDATE_DATE
--        , xrsi.LAST_UPDATE_LOGIN       as LAST_UPDATE_LOGIN
--        , xrsi.REQUEST_ID              as REQUEST_ID
--        , xrsi.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
--        , xrsi.PROGRAM_ID              as PROGRAM_ID
--        , xrsi.PROGRAM_UPDATE_DATE     as PROGRAM_UPDATE_DATE
--      FROM
--          XX03_RECEIVABLE_SLIPS_IF     xrsi                         -- �u�����`�[�C���^�[�t�F�C�X�\�v
--        , XX03_SLIP_TYPES_LOV_V        xstl
--        , XX03_PER_PEOPLES_V           xpp
--        , XX03_PER_PEOPLES_V           xpp2
--        , XX03_APPROVER_PERSON_LOV_V   xapl
--        , XX03_AR_CUSTOMER_LOV_V       xacl
--        , XX03_AR_CUST_SITE_LOV_V      xcsl
--        , XX03_CONVERSION_TYPES_V      xct
--        , XX03_TERMS_LOV_V             xtl
--        , RA_CUST_TRX_TYPES            xttl
--        ,( select a.NAME
--                , a.CURRENCY_CODE
--                , a.BATCH_SOURCE_ID
--                , b.CUSTOMER_NUMBER
--                , b.LOCATION_NUMBER
--          from    XX03_RECEIPT_METHOD_LOV_V a
--                , XX03_AR_CUST_SITE_LOV_V   b
--          where   a.ADDRESS_ID = b.ADDRESS_ID
--          ) xrml
--      WHERE
--            xrsi.REQUEST_ID              = h_request_id
--        AND xrsi.SOURCE                  = h_source
--        AND xrsi.SLIP_TYPE_NAME          = xstl.DESCRIPTION         (+)
--        AND xrsi.REQUESTOR_PERSON_NUMBER = xpp.EMPLOYEE_NUMBER      (+)
--        AND xrsi.ENTRY_PERSON_NUMBER     = xpp2.EMPLOYEE_NUMBER     (+)
--        AND xrsi.APPROVER_PERSON_NUMBER  = xapl.EMPLOYEE_NUMBER     (+)
--        AND xrsi.CUSTOMER_NUMBER         = xacl.CUSTOMER_NUMBER     (+)
--        AND xrsi.CUSTOMER_NUMBER         = xcsl.CUSTOMER_NUMBER     (+)
--        AND xrsi.LOCATION                = xcsl.LOCATION_NUMBER     (+)
--        AND xrsi.CONVERSION_TYPE         = xct.USER_CONVERSION_TYPE (+)
--        AND xrsi.TERMS_NAME              = xtl.NAME                 (+)
--        AND xrsi.TRANS_TYPE_NAME         = xttl.NAME                (+)
--        AND xrsi.CUSTOMER_NUMBER         = xrml.CUSTOMER_NUMBER     
--        AND xrsi.LOCATION                = xrml.LOCATION_NUMBER     
--        AND xrsi.RECEIPT_METHOD_NAME     = xrml.NAME                
--        AND xrsi.CURRENCY_CODE           = xrml.CURRENCY_CODE       
--    UNION ALL
--      SELECT
--          xrsi.INTERFACE_ID            as INTERFACE_ID              -- �C���^�[�t�F�[�XID
--        , xrsi.WF_STATUS               as WF_STATUS                 -- �X�e�[�^�X
--        , xstl.LOOKUP_CODE             as SLIP_TYPE                 -- �`�[���
--        , TRUNC(xrsi.ENTRY_DATE, 'DD') as ENTRY_DATE                -- �N�[��
--        , xpp.PERSON_ID                as REQUESTOR_PERSON_ID       -- �\����
--        , xpp.EMPLOYEE_DISP            as REQUESTOR_PERSON_NAME     -- �\���Җ�
--        , xapl.PERSON_ID               as APPROVER_PERSON_ID        -- ���F��
--        , xapl.EMPLOYEE_DISP           as APPROVER_PERSON_NAME      -- ���F�Җ�
--        , xrsi.INVOICE_DATE            as INVOICE_DATE              -- ���������t
--        , xttl.CUST_TRX_TYPE_ID        as TRANS_TYPE_ID             -- ����^�C�vID
--        , xrsi.TRANS_TYPE_NAME         as TRANS_TYPE_NAME           -- ����^�C�v��
--        , xacl.CUSTOMER_ID             as CUSTOMER_ID               -- �ڋqID
--        , xacl.CUSTOMER_NAME           as CUSTOMER_NAME             -- �ڋq��
--        , xcsl.ADDRESS_ID              as CUSTOMER_OFFICE_ID        -- �ڋq���Ə�ID
--        , xrsi.LOCATION                as CUSTOMER_OFFICE_NAME      -- �ڋq���Ə���
--        , xrsi.CURRENCY_CODE           as INVOICE_CURRENCY_CODE     -- �ʉ�
--        , xrsi.CONVERSION_RATE         as CONVERSION_RATE           -- ���[�g
--        , xct.CONVERSION_TYPE          as EXCHANGE_RATE_TYPE        -- ���[�g�^�C�v
--        , xrsi.CONVERSION_TYPE         as EXCHANGE_RATE_TYPE_NAME   -- ���[�g�^�C�v��
--        , xtl.TERMSID                  as TERMS_ID                  -- �x������ID
--        , xrsi.TERMS_NAME              as TERMS_NAME                -- �x��������
--        , xrsi.DESCRIPTION             as DESCRIPTION               -- ���l
--        , xpp.ATTRIBUTE28              as ENTRY_DEPARTMENT          -- �N�[����
--        , xpp2.PERSON_ID               as ENTRY_PERSON_ID           -- �`�[���͎�
--        , xrsi.GL_DATE                 as GL_DATE                   -- �v���
--        , NULL                         as RECEIPT_METHOD_ID         -- �x�����@ID
--        , xrsi.RECEIPT_METHOD_NAME     as RECEIPT_METHOD_NAME       -- �x�����@��
--        , xrsi.ONETIME_CUSTOMER_NAME       as ONETIME_CUSTOMER_NAME       -- �ڋq����
--        , xrsi.ONETIME_CUSTOMER_KANA_NAME  as ONETIME_CUSTOMER_KANA_NAME  -- �J�i��
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_1  as ONETIME_CUSTOMER_ADDRESS_1  -- �Z���P
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_2  as ONETIME_CUSTOMER_ADDRESS_2  -- �Z���Q
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_3  as ONETIME_CUSTOMER_ADDRESS_3  -- �Z���R
--        , xcsl.TAX_HEADER_LEVEL_FLAG   as AUTO_TAX_CALC_FLAG              -- ����Ōv�Z���x��(���Ə��P��)
--        , SUBSTRB(xcsl.TAX_ROUNDING_RULE, 1, 1)   as TAX_ROUNDING_RULE    -- ����Œ[������(���Ə��P��)
--        , xcsl.TAX_HEADER_LEVEL_FLAG_C as AUTO_TAX_CALC_FLAG_C            -- ����Ōv�Z���x��(�ڋq�P��)
--        , SUBSTRB(xcsl.TAX_ROUNDING_RULE_C, 1, 1) as TAX_ROUNDING_RULE_C  -- ����Œ[������(�ڋq�P��)
--        , xrsi.COMMITMENT_NUMBER       as COMMITMENT_NUMBER         -- �O����[���`�[�ԍ�
--        , xrsi.ORG_ID                  as ORG_ID                    -- �I���OID
--        , xrsi.CREATED_BY              as CREATED_BY
--        , xrsi.CREATION_DATE           as CREATION_DATE
--        , xrsi.LAST_UPDATED_BY         as LAST_UPDATED_BY
--        , xrsi.LAST_UPDATE_DATE        as LAST_UPDATE_DATE
--        , xrsi.LAST_UPDATE_LOGIN       as LAST_UPDATE_LOGIN
--        , xrsi.REQUEST_ID              as REQUEST_ID
--        , xrsi.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
--        , xrsi.PROGRAM_ID              as PROGRAM_ID
--        , xrsi.PROGRAM_UPDATE_DATE     as PROGRAM_UPDATE_DATE
--      FROM
--          XX03_RECEIVABLE_SLIPS_IF     xrsi                         -- �u�����`�[�C���^�[�t�F�C�X�\�v
--        , XX03_SLIP_TYPES_LOV_V        xstl
--        , XX03_PER_PEOPLES_V           xpp
--        , XX03_PER_PEOPLES_V           xpp2
--        , XX03_APPROVER_PERSON_LOV_V   xapl
--        , XX03_AR_CUSTOMER_LOV_V       xacl
--        , XX03_AR_CUST_SITE_LOV_V      xcsl
--        , XX03_CONVERSION_TYPES_V      xct
--        , XX03_TERMS_LOV_V             xtl
--        , RA_CUST_TRX_TYPES            xttl
--      WHERE
--            xrsi.REQUEST_ID              = h_request_id
--        AND xrsi.SOURCE                  = h_source
--        AND xrsi.SLIP_TYPE_NAME          = xstl.DESCRIPTION         (+)
--        AND xrsi.REQUESTOR_PERSON_NUMBER = xpp.EMPLOYEE_NUMBER      (+)
--        AND xrsi.ENTRY_PERSON_NUMBER     = xpp2.EMPLOYEE_NUMBER     (+)
--        AND xrsi.APPROVER_PERSON_NUMBER  = xapl.EMPLOYEE_NUMBER     (+)
--        AND xrsi.CUSTOMER_NUMBER         = xacl.CUSTOMER_NUMBER     (+)
--        AND xrsi.CUSTOMER_NUMBER         = xcsl.CUSTOMER_NUMBER     (+)
--        AND xrsi.LOCATION                = xcsl.LOCATION_NUMBER     (+)
--        AND xrsi.CONVERSION_TYPE         = xct.USER_CONVERSION_TYPE (+)
--        AND xrsi.TERMS_NAME              = xtl.NAME                 (+)
--        AND xrsi.TRANS_TYPE_NAME         = xttl.NAME                (+)
--        AND NOT EXISTS
--            (SELECT * 
--             FROM   XX03_RECEIPT_METHOD_LOV_V a
--                  , XX03_AR_CUST_SITE_LOV_V   b
--             WHERE  a.ADDRESS_ID      = b.ADDRESS_ID
--               AND  b.CUSTOMER_NUMBER = xrsi.CUSTOMER_NUMBER
--               AND  b.LOCATION_NUMBER = xrsi.LOCATION
--               AND  a.NAME            = xrsi.RECEIPT_METHOD_NAME
--               AND  a.CURRENCY_CODE   = xrsi.CURRENCY_CODE
--            )
--    )
--    ORDER BY
--      INTERFACE_ID
--  ;
------ ver 1.2 Change Start
----    SELECT
----        xrsi.INTERFACE_ID            as INTERFACE_ID              -- �C���^�[�t�F�[�XID
----      , xrsi.WF_STATUS               as WF_STATUS                 -- �X�e�[�^�X
----      , xstl.LOOKUP_CODE             as SLIP_TYPE                 -- �`�[���
----      , TRUNC(xrsi.ENTRY_DATE, 'DD') as ENTRY_DATE                -- �N�[��
----      , xpp.PERSON_ID                as REQUESTOR_PERSON_ID       -- �\����
----      , xpp.EMPLOYEE_DISP            as REQUESTOR_PERSON_NAME     -- �\���Җ�
----      , xapl.PERSON_ID               as APPROVER_PERSON_ID        -- ���F��
----      , xapl.EMPLOYEE_DISP           as APPROVER_PERSON_NAME      -- ���F�Җ�
----      , xrsi.INVOICE_DATE            as INVOICE_DATE              -- ���������t
------      , xrsi.TRANS_TYPE_ID           as TRANS_TYPE_ID             -- ����^�C�vID
------      , xttl.NAME                    as TRANS_TYPE_NAME           -- ����^�C�v��
------      , xrsi.CUSTOMER_ID             as CUSTOMER_ID               -- �ڋqID
----      , xttl.CUST_TRX_TYPE_ID        as TRANS_TYPE_ID             -- ����^�C�vID
----      , xrsi.TRANS_TYPE_NAME         as TRANS_TYPE_NAME           -- ����^�C�v��
----      , xacl.CUSTOMER_ID             as CUSTOMER_ID               -- �ڋqID
----      , xacl.CUSTOMER_NAME           as CUSTOMER_NAME             -- �ڋq��
------      , xrsi.CUSTOMER_OFFICE_ID      as CUSTOMER_OFFICE_ID        -- �ڋq���Ə�ID
------      , xcsl.LOCATION                as CUSTOMER_OFFICE_NAME      -- �ڋq���Ə���
----      , xcsl.ADDRESS_ID              as CUSTOMER_OFFICE_ID        -- �ڋq���Ə�ID
----      , xrsi.LOCATION                as CUSTOMER_OFFICE_NAME      -- �ڋq���Ə���
----      , xrsi.CURRENCY_CODE           as INVOICE_CURRENCY_CODE     -- �ʉ�
----      , xrsi.CONVERSION_RATE         as CONVERSION_RATE           -- ���[�g
----      , xct.CONVERSION_TYPE          as EXCHANGE_RATE_TYPE        -- ���[�g�^�C�v
----      , xrsi.CONVERSION_TYPE         as EXCHANGE_RATE_TYPE_NAME   -- ���[�g�^�C�v��
----      , xtl.TERMSID                  as TERMS_ID                  -- �x������ID
----      , xrsi.TERMS_NAME              as TERMS_NAME                -- �x��������
----      , xrsi.DESCRIPTION             as DESCRIPTION               -- ���l
----      , xpp.ATTRIBUTE28              as ENTRY_DEPARTMENT          -- �N�[����
----      , xpp2.PERSON_ID               as ENTRY_PERSON_ID           -- �`�[���͎�
----      , xrsi.GL_DATE                 as GL_DATE                   -- �v���
----      , xrml.BATCH_SOURCE_ID         as RECEIPT_METHOD_ID         -- �x�����@ID
----      , xrsi.RECEIPT_METHOD_NAME     as RECEIPT_METHOD_NAME       -- �x�����@��
----      ,xrsi.ONETIME_CUSTOMER_NAME       as ONETIME_CUSTOMER_NAME       -- �ڋq����
----      ,xrsi.ONETIME_CUSTOMER_KANA_NAME  as ONETIME_CUSTOMER_KANA_NAME  -- �J�i��
----      ,xrsi.ONETIME_CUSTOMER_ADDRESS_1  as ONETIME_CUSTOMER_ADDRESS_1  -- �Z���P
----      ,xrsi.ONETIME_CUSTOMER_ADDRESS_2  as ONETIME_CUSTOMER_ADDRESS_2  -- �Z���Q
----      ,xrsi.ONETIME_CUSTOMER_ADDRESS_3  as ONETIME_CUSTOMER_ADDRESS_3  -- �Z���R
----      , xcsl.TAX_HEADER_LEVEL_FLAG   as AUTO_TAX_CALC_FLAG              -- ����Ōv�Z���x��(���Ə��P��)
----      , SUBSTRB(xcsl.TAX_ROUNDING_RULE, 1, 1)   as TAX_ROUNDING_RULE    -- ����Œ[������(���Ə��P��)
----      , xcsl.TAX_HEADER_LEVEL_FLAG_C as AUTO_TAX_CALC_FLAG_C            -- ����Ōv�Z���x��(�ڋq�P��)
----      , SUBSTRB(xcsl.TAX_ROUNDING_RULE_C, 1, 1) as TAX_ROUNDING_RULE_C  -- ����Œ[������(�ڋq�P��)
----      , xrsi.COMMITMENT_NUMBER       as COMMITMENT_NUMBER         -- �O����[���`�[�ԍ�
----      , xrsi.ORG_ID                  as ORG_ID                    -- �I���OID
----      , xrsi.CREATED_BY              as CREATED_BY
----      , xrsi.CREATION_DATE           as CREATION_DATE
----      , xrsi.LAST_UPDATED_BY         as LAST_UPDATED_BY
----      , xrsi.LAST_UPDATE_DATE        as LAST_UPDATE_DATE
----      , xrsi.LAST_UPDATE_LOGIN       as LAST_UPDATE_LOGIN
----      , xrsi.REQUEST_ID              as REQUEST_ID
----      , xrsi.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
----      , xrsi.PROGRAM_ID              as PROGRAM_ID
----      , xrsi.PROGRAM_UPDATE_DATE     as PROGRAM_UPDATE_DATE
----     FROM
----        XX03_RECEIVABLE_SLIPS_IF     xrsi                         -- �u�����`�[�C���^�[�t�F�C�X�\�v
----      , XX03_SLIP_TYPES_LOV_V        xstl
----      , XX03_PER_PEOPLES_V           xpp
----      , XX03_PER_PEOPLES_V           xpp2
----      , XX03_APPROVER_PERSON_LOV_V   xapl
----      , XX03_AR_CUSTOMER_LOV_V       xacl
----      , XX03_AR_CUST_SITE_LOV_V      xcsl
----      , XX03_CONVERSION_TYPES_V      xct
----      , XX03_TERMS_LOV_V             xtl
------      , XX03_RECEIPT_METHOD_LOV_V    xrml
------      , RA_CUST_TRX_TYPES_ALL        xttl
----      , RA_CUST_TRX_TYPES            xttl
----      ,( select a.NAME
----              , a.CURRENCY_CODE
----              , a.BATCH_SOURCE_ID
----              , b.CUSTOMER_NUMBER
----              , b.LOCATION_NUMBER
----        from    XX03_RECEIPT_METHOD_LOV_V a
----              , XX03_AR_CUST_SITE_LOV_V   b
----        where   a.ADDRESS_ID = b.ADDRESS_ID
----        ) xrml
----     WHERE
----          xrsi.REQUEST_ID              = h_request_id
----      AND xrsi.SOURCE                  = h_source
----      AND xrsi.SLIP_TYPE_NAME          = xstl.DESCRIPTION         (+)
----      AND xrsi.REQUESTOR_PERSON_NUMBER = xpp.EMPLOYEE_NUMBER      (+)
----      AND xrsi.ENTRY_PERSON_NUMBER     = xpp2.EMPLOYEE_NUMBER     (+)
----      AND xrsi.APPROVER_PERSON_NUMBER  = xapl.EMPLOYEE_NUMBER     (+)
------      AND xrsi.CUSTOMER_ID             = xacl.CUSTOMER_ID         (+)
------      AND xrsi.CUSTOMER_ID             = xcsl.CUSTOMER_ID         (+)
------      AND xrsi.CUSTOMER_OFFICE_ID      = xcsl.ADDRESS_ID          (+)
----      AND xrsi.CUSTOMER_NUMBER         = xacl.CUSTOMER_NUMBER     (+)
----      AND xrsi.CUSTOMER_NUMBER         = xcsl.CUSTOMER_NUMBER     (+)
----      AND xrsi.LOCATION                = xcsl.LOCATION_NUMBER     (+)
----      AND xrsi.CONVERSION_TYPE         = xct.USER_CONVERSION_TYPE (+)
----      AND xrsi.TERMS_NAME              = xtl.NAME                 (+)
------      AND xrsi.RECEIPT_METHOD_NAME     = xrml.NAME                (+)
----      AND xrsi.CUSTOMER_NUMBER         = xrml.CUSTOMER_NUMBER     (+)
----      AND xrsi.LOCATION                = xrml.LOCATION_NUMBER     (+)
----      AND xrsi.RECEIPT_METHOD_NAME     = xrml.NAME                (+)
----      AND xrsi.CURRENCY_CODE           = xrml.CURRENCY_CODE       (+)
------      AND xrsi.TRANS_TYPE_ID           = xttl.CUST_TRX_TYPE_ID    (+)
----      AND xrsi.TRANS_TYPE_NAME         = xttl.NAME                (+)
----     ORDER BY
----      xrsi.INTERFACE_ID
----  ;
------ ver 1.2 Change End
---- ver 11.5.10.1.0 Change End
----
--  --  �w�b�_���J�[�\�����R�[�h�^
--  xx03_if_header_rec    xx03_if_header_cur%ROWTYPE;
--
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
-- Ver11.5.10.1.6 Add Start
     , HEAD.SLIP_TYPE_APP          as HEAD_SLIP_TYPE_APP                 -- �`�[��ʃA�v���P�[�V����
-- Ver11.5.10.1.6 Add End
     , HEAD.ENTRY_DATE             as HEAD_ENTRY_DATE                    -- �N�[��
     , HEAD.REQUESTOR_PERSON_ID    as HEAD_REQUESTOR_PERSON_ID           -- �\����
     , HEAD.REQUESTOR_PERSON_NAME  as HEAD_REQUESTOR_PERSON_NAME         -- �\���Җ�
     , HEAD.APPROVER_PERSON_ID     as HEAD_APPROVER_PERSON_ID            -- ���F��
     , HEAD.APPROVER_PERSON_NAME   as HEAD_APPROVER_PERSON_NAME          -- ���F�Җ�
     , HEAD.INVOICE_DATE           as HEAD_INVOICE_DATE                  -- ���������t
     , HEAD.TRANS_TYPE_ID          as HEAD_TRANS_TYPE_ID                 -- ����^�C�vID
     , HEAD.TRANS_TYPE_NAME        as HEAD_TRANS_TYPE_NAME               -- ����^�C�v��
     , HEAD.CUSTOMER_ID            as HEAD_CUSTOMER_ID                   -- �ڋqID
     , HEAD.CUSTOMER_NAME          as HEAD_CUSTOMER_NAME                 -- �ڋq��
     , HEAD.CUSTOMER_OFFICE_ID     as HEAD_CUSTOMER_OFFICE_ID            -- �ڋq���Ə�ID
     , HEAD.CUSTOMER_OFFICE_NAME   as HEAD_CUSTOMER_OFFICE_NAME          -- �ڋq���Ə���
     , HEAD.INVOICE_CURRENCY_CODE  as HEAD_INVOICE_CURRENCY_CODE         -- �ʉ�
     -- ver 11.5.10.2.10D Add Start
     , HEAD.CHK_CURRENCY_CODE      as HEAD_CHK_CURRENCY_CODE             -- �ʉ݃}�X�^�`�F�b�N�p
     -- ver 11.5.10.2.10D Add End
     , HEAD.CONVERSION_RATE        as HEAD_CONVERSION_RATE               -- ���[�g
     , HEAD.EXCHANGE_RATE_TYPE     as HEAD_EXCHANGE_RATE_TYPE            -- ���[�g�^�C�v
     , HEAD.EXCHANGE_RATE_TYPE_NAME  as HEAD_EXCHANGE_RATE_TYPE_NAME     -- ���[�g�^�C�v��
     , HEAD.TERMS_ID               as HEAD_TERMS_ID                      -- �x������ID
     , HEAD.TERMS_NAME             as HEAD_TERMS_NAME                    -- �x��������
     , HEAD.DESCRIPTION            as HEAD_DESCRIPTION                   -- ���l
     , HEAD.ENTRY_DEPARTMENT       as HEAD_ENTRY_DEPARTMENT              -- �N�[����
     , HEAD.ENTRY_PERSON_ID        as HEAD_ENTRY_PERSON_ID               -- �`�[���͎�
     , HEAD.GL_DATE                as HEAD_GL_DATE                       -- �v���
     , HEAD.RECEIPT_METHOD_ID      as HEAD_RECEIPT_METHOD_ID             -- �x�����@ID
     , HEAD.RECEIPT_METHOD_NAME    as HEAD_RECEIPT_METHOD_NAME           -- �x�����@��
     , HEAD.ONETIME_CUSTOMER_NAME       as HEAD_ONE_CUSTOMER_NAME        -- �ڋq����
     , HEAD.ONETIME_CUSTOMER_KANA_NAME  as HEAD_ONE_CUSTOMER_KANA_NAME   -- �J�i��
     , HEAD.ONETIME_CUSTOMER_ADDRESS_1  as HEAD_ONE_CUSTOMER_ADDRESS_1   -- �Z���P
     , HEAD.ONETIME_CUSTOMER_ADDRESS_2  as HEAD_ONE_CUSTOMER_ADDRESS_2   -- �Z���Q
     , HEAD.ONETIME_CUSTOMER_ADDRESS_3  as HEAD_ONE_CUSTOMER_ADDRESS_3   -- �Z���R
     , HEAD.AUTO_TAX_CALC_FLAG     as HEAD_AUTO_TAX_CALC_FLAG            -- ����Ōv�Z���x��(���Ə��P��)
     , HEAD.TAX_ROUNDING_RULE      as HEAD_TAX_ROUNDING_RULE             -- ����Œ[������(���Ə��P��)
     , HEAD.AUTO_TAX_CALC_FLAG_C   as HEAD_AUTO_TAX_CALC_FLAG_C          -- ����Ōv�Z���x��(�ڋq�P��)
     , HEAD.TAX_ROUNDING_RULE_C    as HEAD_TAX_ROUNDING_RULE_C           -- ����Œ[������(�ڋq�P��)
     , HEAD.COMMITMENT_NUMBER      as HEAD_COMMITMENT_NUMBER             -- �O����[���`�[�ԍ�
     , HEAD.COM_TRX_NUMBER         as HEAD_COM_TRX_NUMBER                --
     , HEAD.COM_COMMITMENT_AMOUNT  as HEAD_COM_COMMITMENT_AMOUNT         --
     , HEAD.ORG_ID                 as HEAD_ORG_ID                        -- �I���OID
     , HEAD.CREATED_BY             as HEAD_CREATED_BY                    -- 
     , HEAD.CREATION_DATE          as HEAD_CREATION_DATE                 -- 
     , HEAD.LAST_UPDATED_BY        as HEAD_LAST_UPDATED_BY               -- 
     , HEAD.LAST_UPDATE_DATE       as HEAD_LAST_UPDATE_DATE              -- 
     , HEAD.LAST_UPDATE_LOGIN      as HEAD_LAST_UPDATE_LOGIN             -- 
     , HEAD.REQUEST_ID             as HEAD_REQUEST_ID                    -- 
     , HEAD.PROGRAM_APPLICATION_ID as HEAD_PROGRAM_APPLICATION_ID        -- 
     , HEAD.PROGRAM_ID             as HEAD_PROGRAM_ID                    -- 
     , HEAD.PROGRAM_UPDATE_DATE    as HEAD_PROGRAM_UPDATE_DATE           -- 
     -- ver 11.5.10.2.13 Add Start
     , HEAD.PAYMENT_ELE_DATA_YES   as HEAD_PAYMENT_ELE_DATA_YES          -- �x���ē����d�q�f�[�^��̂���
     , HEAD.PAYMENT_ELE_DATA_NO    as HEAD_PAYMENT_ELE_DATA_NO           -- �x���ē����d�q�f�[�^��̂Ȃ�
     -- ver 11.5.10.2.13 Add End
-- Ver11.5.10.2.14 ADD START
     , NVL(
         HEAD.DRAFTING_COMPANY
        ,'001'
       )                           as DRAFTING_COMPANY                   -- �`�[�쐬���
-- Ver11.5.10.2.14 ADD END
     , LINE.INTERFACE_ID           as LINE_INTERFACE_ID                  -- �C���^�[�t�F�[�XID
     , LINE.LINE_NUMBER            as LINE_LINE_NUMBER                   -- ���C���i���o�[
     , LINE.SLIP_LINE_TYPE_NAME    as LINE_SLIP_LINE_TYPE_NAME           -- �������e
     , LINE.SLIP_LINE_TYPE         as LINE_SLIP_LINE_TYPE                -- �������eID
     , LINE.ENTERED_TAX_AMOUNT     as LINE_ENTERED_TAX_AMOUNT            -- ���׏���Ŋz
     , LINE.SLIP_LINE_UOM          as LINE_SLIP_LINE_UOM                 -- �P��
     , LINE.SLIP_LINE_UOM_NAME     as LINE_SLIP_LINE_UOM_NAME            -- �P�ʖ�
     , LINE.SLIP_LINE_UNIT_PRICE   as LINE_SLIP_LINE_UNIT_PRICE          -- �P��
     , LINE.SLIP_LINE_QUANTITY     as LINE_SLIP_LINE_QUANTITY            -- ����
     , LINE.SLIP_LINE_ENTERED_AMOUNT  as LINE_SLIP_LINE_ENTERED_AMOUNT   -- ���͋��z
     , LINE.SLIP_LINE_RECIEPT_NO   as LINE_SLIP_LINE_RECIEPT_NO          -- �[�i���ԍ�
     , LINE.SLIP_DESCRIPTION       as LINE_SLIP_DESCRIPTION              -- ���l�i���ׁj
     , LINE.SLIP_LINE_TAX_FLAG     as LINE_SLIP_LINE_TAX_FLAG            -- ����
     , LINE.SLIP_LINE_TAX_CODE     as LINE_SLIP_LINE_TAX_CODE            -- �ŋ敪
     , LINE.TAX_NAME               as LINE_TAX_NAME                      -- �ŋ敪��
     , LINE.VAT_TAX_ID             as LINE_VAT_TAX_ID                    -- �ŋ敪ID
     -- Ver11.5.10.1.5C 2005/10/21 Add Start
     , LINE.MST_TAX_FLAG           as LINE_MST_TAX_FLAG                  -- �ŋ敪�̓��Ńt���O
     -- Ver11.5.10.1.5C 2005/10/21 Add End
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
     , LINE.SEGMENT8               as LINE_SEGMENT8                      -- �\���P
     , LINE.SEGMENT8_NAME          as LINE_SEGMENT8_NAME                 -- �\��
     , LINE.INCR_DECR_REASON_CODE  as LINE_INCR_DECR_REASON_CODE         -- �������R
     , LINE.INCR_DECR_REASON_NAME  as LINE_INCR_DECR_REASON_NAME         -- �������R��
     , LINE.RECON_REFERENCE        as LINE_RECON_REFERENCE               -- �����Q��
     , LINE.JOURNAL_DESCRIPTION    as LINE_JOURNAL_DESCRIPTION           -- ���l�i���ׁj
     , LINE.ORG_ID                 as LINE_ORG_ID                        -- �I���OID
-- ==  11.5.10.2.12 Added START ===============================================================
     , LINE.ATTRIBUTE7             as LINE_ATTRIBUTE7                    -- �g�c���ٔԍ�
-- == 2016/12/06 11.5.10.2.12 Added END =================================================================
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
     -- ver 11.5.10.2.6B Add Start
     , CNT2.INTERFACE_ID           as CNT2_INTERFACE_ID                  -- �C���^�[�t�F�[�XID
     , CNT2.LINE_SUM_NO_FLG        as CNT2_LINE_SUM_NO_FLG               --
     -- ver 11.5.10.2.6B Add End
     -- ver 11.5.10.2.10F Add Start
     , APPROVER.PERSON_ID          as APPROVER_PERSON_ID
     -- ver 11.5.10.2.10F Add End
    FROM
       (SELECT /*+ USE_NL(xrsi) */ 
           xrsi.INTERFACE_ID           as INTERFACE_ID                       -- �C���^�[�t�F�[�XID
         , xrsi.WF_STATUS              as WF_STATUS                          -- �X�e�[�^�X
         , xstl.LOOKUP_CODE            as SLIP_TYPE                          -- �`�[���
-- Ver11.5.10.1.6 Add Start
         , xstl.ATTRIBUTE14            as SLIP_TYPE_APP                      -- �`�[��ʃA�v���P�[�V����
-- Ver11.5.10.1.6 Add End
         , TRUNC(xrsi.ENTRY_DATE, 'DD')  as ENTRY_DATE                       -- �N�[��
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
         , xrsi.INVOICE_DATE           as INVOICE_DATE                       -- ���������t
         , xttl.CUST_TRX_TYPE_ID       as TRANS_TYPE_ID                      -- ����^�C�vID
         , xrsi.TRANS_TYPE_NAME        as TRANS_TYPE_NAME                    -- ����^�C�v��
         , xacl.CUSTOMER_ID            as CUSTOMER_ID                        -- �ڋqID
         , xacl.CUSTOMER_NAME          as CUSTOMER_NAME                      -- �ڋq��
         , xcsl.ADDRESS_ID             as CUSTOMER_OFFICE_ID                 -- �ڋq���Ə�ID
         , xrsi.LOCATION               as CUSTOMER_OFFICE_NAME               -- �ڋq���Ə���
         , xrsi.CURRENCY_CODE          as INVOICE_CURRENCY_CODE              -- �ʉ�
         -- ver 11.5.10.2.10D Add Start
         , xfc.CURRENCY_CODE           as CHK_CURRENCY_CODE                  -- �ʉ݃}�X�^�`�F�b�N�p
         -- ver 11.5.10.2.10D Add End
         , xrsi.CONVERSION_RATE        as CONVERSION_RATE                    -- ���[�g
         , xct.CONVERSION_TYPE         as EXCHANGE_RATE_TYPE                 -- ���[�g�^�C�v
         , xrsi.CONVERSION_TYPE        as EXCHANGE_RATE_TYPE_NAME            -- ���[�g�^�C�v��
         , xtl.TERMSID                 as TERMS_ID                           -- �x������ID
         , xrsi.TERMS_NAME             as TERMS_NAME                         -- �x��������
         , xrsi.DESCRIPTION            as DESCRIPTION                        -- ���l
         , xpp.ATTRIBUTE28             as ENTRY_DEPARTMENT                   -- �N�[����
         , xpp2.PERSON_ID              as ENTRY_PERSON_ID                    -- �`�[���͎�
         , xrsi.GL_DATE                as GL_DATE                            -- �v���
         , xrml.BATCH_SOURCE_ID        as RECEIPT_METHOD_ID                  -- �x�����@ID
         , xrsi.RECEIPT_METHOD_NAME    as RECEIPT_METHOD_NAME                -- �x�����@��
         , xrsi.ONETIME_CUSTOMER_NAME       as ONETIME_CUSTOMER_NAME         -- �ڋq����
         , xrsi.ONETIME_CUSTOMER_KANA_NAME  as ONETIME_CUSTOMER_KANA_NAME    -- �J�i��
         , xrsi.ONETIME_CUSTOMER_ADDRESS_1  as ONETIME_CUSTOMER_ADDRESS_1    -- �Z���P
         , xrsi.ONETIME_CUSTOMER_ADDRESS_2  as ONETIME_CUSTOMER_ADDRESS_2    -- �Z���Q
         , xrsi.ONETIME_CUSTOMER_ADDRESS_3  as ONETIME_CUSTOMER_ADDRESS_3    -- �Z���R
         , xcsl.TAX_HEADER_LEVEL_FLAG               as AUTO_TAX_CALC_FLAG    -- ����Ōv�Z���x��(���Ə��P��)
         , SUBSTRB(xcsl.TAX_ROUNDING_RULE, 1, 1)    as TAX_ROUNDING_RULE     -- ����Œ[������(���Ə��P��)
         , xcsl.TAX_HEADER_LEVEL_FLAG_C             as AUTO_TAX_CALC_FLAG_C  -- ����Ōv�Z���x��(�ڋq�P��)
         , SUBSTRB(xcsl.TAX_ROUNDING_RULE_C, 1, 1)  as TAX_ROUNDING_RULE_C   -- ����Œ[������(�ڋq�P��)
         , xrsi.COMMITMENT_NUMBER      as COMMITMENT_NUMBER                  -- �O����[���`�[�ԍ�
-- 2012/10/24 Ver11.5.10.2.11 START
--         , xcnl.TRX_NUMBER             as COM_TRX_NUMBER                     --
--         -- ver 11.5.10.2.10E Chg Start
--         --, xcnl.COMMITMENT_AMOUNT      as COM_COMMITMENT_AMOUNT              --
--         , to_number(xcnl.COMMITMENT_AMOUNT, xx00_currency_pkg.get_format_mask(xrsi.CURRENCY_CODE, 38)) as COM_COMMITMENT_AMOUNT
--         -- ver 11.5.10.2.10E Chg End
         , NULL                        as COM_TRX_NUMBER
         , NULL                        as COM_COMMITMENT_AMOUNT
-- 2012/10/24 Ver11.5.10.2.11 END
         , xrsi.ORG_ID                 as ORG_ID                             -- �I���OID
         , xrsi.CREATED_BY             as CREATED_BY
         , xrsi.CREATION_DATE          as CREATION_DATE
         , xrsi.LAST_UPDATED_BY        as LAST_UPDATED_BY
         , xrsi.LAST_UPDATE_DATE       as LAST_UPDATE_DATE
         , xrsi.LAST_UPDATE_LOGIN      as LAST_UPDATE_LOGIN
         , xrsi.REQUEST_ID             as REQUEST_ID
         , xrsi.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
         , xrsi.PROGRAM_ID             as PROGRAM_ID
         , xrsi.PROGRAM_UPDATE_DATE    as PROGRAM_UPDATE_DATE
         -- ver 11.5.10.2.13 Add Start
         , xrsi.PAYMENT_ELE_DATA_YES   as PAYMENT_ELE_DATA_YES               -- �x���ē����d�q�f�[�^��̂���
         , xrsi.PAYMENT_ELE_DATA_NO    as PAYMENT_ELE_DATA_NO                -- �x���ē����d�q�f�[�^��̂Ȃ�
         -- ver 11.5.10.2.13 Add End
-- Ver11.5.10.2.14 ADD START
         , xttl.DRAFTING_COMPANY       as DRAFTING_COMPANY                   -- �`�[�쐬���
-- Ver11.5.10.2.14 ADD END
        FROM
           XX03_RECEIVABLE_SLIPS_IF    xrsi    --�u�����`�[�C���^�[�t�F�C�X�\�v
-- ver 11.5.10.2.7 Chg Start
-- -- Ver11.5.10.1.6C Chg Start
-- -- -- Ver11.5.10.1.6 Chg Start
-- -- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION
-- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION,XLXV.ATTRIBUTE14
-- -- -- Ver11.5.10.1.6 Chg End
-- --           FROM XX03_SLIP_TYPES_V XLXV
-- --           WHERE XLXV.ENABLED_FLAG = 'Y'
-- --           )                           xstl
--          ,(SELECT XSTLV.LOOKUP_CODE,XSTLV.DESCRIPTION,XSTLV.ATTRIBUTE14
--            FROM XX03_SLIP_TYPES_LOV_V XSTLV
--            WHERE XSTLV.ATTRIBUTE14 = 'AR'
--            )                           xstl
-- -- Ver11.5.10.1.6C Chg End
         ,(select XSTLV.LOOKUP_CODE , XSTLV.DESCRIPTION , XSTLV.ATTRIBUTE14
             from XX03_SLIP_TYPES_LOV_V XSTLV , FND_FORM_FUNCTIONS FFF
            where XSTLV.ATTRIBUTE14 = 'AR'
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
         , XX03_PER_PEOPLES_V          xpp
         , XX03_PER_PEOPLES_V          xpp2
-- Ver11.5.10.1.5B Chg Start
         --, XX03_APPROVER_PERSON_LOV_V  xapl
         , PER_PEOPLE_F                ppf
-- Ver11.5.10.1.5B Chg End
         ,(SELECT RAC_BILL.ACCOUNT_NUMBER || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || RAC_BILL_PARTY.PARTY_NAME  CUSTOMER_NAME
                , RAC_BILL.CUST_ACCOUNT_ID  CUSTOMER_ID , RAC_BILL.ACCOUNT_NUMBER  CUSTOMER_NUMBER
           FROM  HZ_CUST_ACCOUNTS  RAC_BILL , HZ_PARTIES  RAC_BILL_PARTY , HZ_CUST_ACCT_SITES  RAA_BILL , HZ_CUST_SITE_USES  SU_BILL , HZ_PARTY_SITES  RAA_BILL_PS
           WHERE RAC_BILL.STATUS = 'A'  AND RAA_BILL_PS.STATUS = 'A'  AND RAC_BILL_PARTY.STATUS = 'A'  AND RAA_BILL.STATUS = 'A'  AND SU_BILL.STATUS = 'A'
             AND SU_BILL.SITE_USE_CODE = 'BILL_TO'  AND SU_BILL.PRIMARY_FLAG = 'Y'  AND RAC_BILL.PARTY_ID = RAC_BILL_PARTY.PARTY_ID
             AND RAC_BILL.CUST_ACCOUNT_ID = RAA_BILL.CUST_ACCOUNT_ID  AND RAA_BILL.PARTY_SITE_ID = RAA_BILL_PS.PARTY_SITE_ID  AND RAA_BILL.CUST_ACCT_SITE_ID = SU_BILL.CUST_ACCT_SITE_ID
           )                           xacl
         ,(SELECT acv.ACCOUNT_NUMBER CUSTOMER_NUMBER , hsuv.LOCATION LOCATION_NUMBER , addr.CUST_ACCT_SITE_ID ADDRESS_ID , hsuv.TAX_HEADER_LEVEL_FLAG TAX_HEADER_LEVEL_FLAG
                , hsuv.TAX_ROUNDING_RULE TAX_ROUNDING_RULE , acv.TAX_HEADER_LEVEL_FLAG TAX_HEADER_LEVEL_FLAG_C , acv.TAX_ROUNDING_RULE TAX_ROUNDING_RULE_C
           FROM HZ_CUST_ACCT_SITES addr , HZ_PARTY_SITES psite , HZ_LOCATIONS loc , HZ_LOC_ASSIGNMENTS loc_ass , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCOUNTS acv
           WHERE addr.CUST_ACCT_SITE_ID = hsuv.CUST_ACCT_SITE_ID AND addr.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID AND addr.PARTY_SITE_ID = psite.PARTY_SITE_ID AND psite.LOCATION_ID = loc.LOCATION_ID
             AND psite.LOCATION_ID = loc_ass.LOCATION_ID AND NVL(addr.ORG_ID,-99) = NVL(loc_ass.ORG_ID,-99) AND hsuv.STATUS = 'A' AND hsuv.SITE_USE_CODE = 'BILL_TO'
           )                           xcsl
         , XX03_CONVERSION_TYPES_V     xct
         -- ver 11.5.10.2.6 Chg Start
         --, XX03_TERMS_LOV_V            xtl
         ,(SELECT rtt.NAME NAME ,rtt.TERM_ID TERMSID ,xrsi.INTERFACE_ID
           FROM RA_TERMS_TL rtt ,RA_TERMS_B rtb ,XX03_RECEIVABLE_SLIPS_IF xrsi
           WHERE rtt.TERM_ID = rtb.TERM_ID AND rtt.LANGUAGE = USERENV('LANG')
             AND xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source AND xrsi.TERMS_NAME = rtt.NAME
             AND xrsi.INVOICE_DATE BETWEEN NVL(rtb.START_DATE_ACTIVE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD'))
                                       AND NVL(rtb.END_DATE_ACTIVE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
           )                           xtl
         -- ver 11.5.10.2.6 Chg End
         -- ver 11.5.10.2.6 Chg Start
         --, RA_CUST_TRX_TYPES           xttl
         ,(SELECT RCT.CUST_TRX_TYPE_ID , RCT.NAME ,xrsi.INTERFACE_ID
-- Ver11.5.10.2.14 ADD START
                 ,RCT.ATTRIBUTE13   AS DRAFTING_COMPANY
-- Ver11.5.10.2.14 ADD END
           FROM RA_CUST_TRX_TYPES_ALL RCT , FND_LOOKUP_VALUES FVL,XX03_SLIP_TYPES_LOV_V XSTLV ,XX03_RECEIVABLE_SLIPS_IF xrsi 
           WHERE RCT.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') AND RCT.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND FVL.LOOKUP_TYPE = 'XX03_SLIP_TYPES'
             AND FVL.LANGUAGE = XX00_GLOBAL_PKG.CURRENT_LANGUAGE AND FVL.ATTRIBUTE15 = RCT.ORG_ID AND FVL.ATTRIBUTE12 = RCT.TYPE
             AND FVL.LOOKUP_CODE = XSTLV.LOOKUP_CODE AND XSTLV.ATTRIBUTE14 = 'AR' AND xrsi.SLIP_TYPE_NAME = XSTLV.DESCRIPTION
             AND xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source AND xrsi.TRANS_TYPE_NAME = RCT.NAME
             AND xrsi.INVOICE_DATE BETWEEN NVL(RCT.START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(RCT.END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
           )                           xttl
         -- ver 11.5.10.2.6 Chg End
         -- ver 11.5.10.2.6 Chg Start
         --,(select arm.NAME as NAME , aba.currency_code as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
         --        ,NVL(arm.START_DATE , TO_DATE('1000/01/01', 'YYYY/MM/DD')) as REC_START_DATE  ,NVL(arm.END_DATE   , TO_DATE('4712/12/31', 'YYYY/MM/DD')) as REC_END_DATE
         --        ,NVL(acrm.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD')) as CUST_START_DATE ,NVL(acrm.END_DATE  , TO_DATE('4712/12/31', 'YYYY/MM/DD')) as CUST_END_DATE
         --        ,hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
         --  from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
         --     , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv
         --  where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
         --    and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'N' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
         --    and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
         --    and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
         --  union all
         --  select arm.NAME as NAME , xclv.CURRENCY_CODE as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
         --        ,NVL(arm.START_DATE , TO_DATE('1000/01/01', 'YYYY/MM/DD')) as REC_START_DATE  ,NVL(arm.END_DATE   , TO_DATE('4712/12/31', 'YYYY/MM/DD')) as REC_END_DATE
         --        ,NVL(acrm.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD')) as CUST_START_DATE ,NVL(acrm.END_DATE  , TO_DATE('4712/12/31', 'YYYY/MM/DD')) as CUST_END_DATE
         --        , hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
         --  from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
         --     , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv , XX03_CURRENCIES_LOV_V xclv
         --  where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
         --    and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'Y' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
         --    and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
         --    and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
         --  )                           xrml
         -- ver 11.5.10.2.10C Chg Start
         --,(select x.NAME ,x.CURRENCY_CODE ,x.BATCH_SOURCE_ID ,x.LOCATION_NUMBER ,x.CUSTOMER_NUMBER ,xrsi.INTERFACE_ID
         --    from (select arm.NAME as NAME , aba.currency_code as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
         --                ,arm.START_DATE  as REC_START_DATE  ,arm.END_DATE  as REC_END_DATE
         --                ,acrm.START_DATE as CUST_START_DATE ,acrm.END_DATE as CUST_END_DATE
         --                ,hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
         --                ,arma.start_date as ARMA_START_DATE , arma.end_date as ARMA_END_DATE
         --                ,aba.inactive_date as ABA_INACTIVE_DATE , abb.end_date as ABB_END_DATE
         --            from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
         --               , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv , AP_BANK_BRANCHES abb
         --           where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
         --             and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'N' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
         --             and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
         --             and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
         --             and aba.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and aba.bank_branch_id = abb.bank_branch_id
         --          union all
         --          select arm.NAME as NAME , xclv.CURRENCY_CODE as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
         --                ,arm.START_DATE  as REC_START_DATE  ,arm.END_DATE  as REC_END_DATE
         --                ,acrm.START_DATE as CUST_START_DATE ,acrm.END_DATE as CUST_END_DATE
         --               , hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
         --                ,arma.start_date as ARMA_START_DATE , arma.end_date as ARMA_END_DATE
         --                ,aba.inactive_date as ABA_INACTIVE_DATE , abb.end_date as ABB_END_DATE
         --            from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
         --               , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv , XX03_CURRENCIES_LOV_V xclv , AP_BANK_BRANCHES abb
         --           where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
         --             and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'Y' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
         --             and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
         --             and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
         --             and aba.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and aba.bank_branch_id = abb.bank_branch_id
         --          ) x ,XX03_RECEIVABLE_SLIPS_IF xrsi
         --   where xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source 
         --     AND xrsi.CUSTOMER_NUMBER = x.CUSTOMER_NUMBER AND xrsi.LOCATION = x.LOCATION_NUMBER AND xrsi.RECEIPT_METHOD_NAME = x.NAME AND xrsi.CURRENCY_CODE = x.CURRENCY_CODE
         --     AND xrsi.INVOICE_DATE BETWEEN NVL(x.REC_START_DATE  ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(x.REC_END_DATE  ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     AND xrsi.INVOICE_DATE BETWEEN NVL(x.CUST_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(x.CUST_END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     AND xrsi.INVOICE_DATE BETWEEN nvl(x.ARMA_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND nvl(x.ARMA_END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     AND xrsi.INVOICE_DATE <  nvl(x.ABA_INACTIVE_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     -- ver 11.5.10.2.10B Chg Start
         --     --AND xrsi.INVOICE_DATE <= nvl(x.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     AND xrsi.INVOICE_DATE <  nvl(x.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     -- ver 11.5.10.2.10B Chg End
         --  )                           xrml
         ,(select x.NAME ,x.CURRENCY_CODE ,x.BATCH_SOURCE_ID ,x.LOCATION_NUMBER ,x.CUSTOMER_NUMBER ,xrsi.INTERFACE_ID
             from (select arm.NAME as NAME , aba.currency_code as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
                         ,arm.START_DATE  as REC_START_DATE  ,arm.END_DATE  as REC_END_DATE
                         ,acrm.START_DATE as CUST_START_DATE ,acrm.END_DATE as CUST_END_DATE
                         ,hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
                         ,arma.start_date as ARMA_START_DATE , arma.end_date as ARMA_END_DATE
                         ,aba.inactive_date as ABA_INACTIVE_DATE , abb.end_date as ABB_END_DATE
                         ,xcv.START_DATE_ACTIVE as CURRENCY_START_DATE , xcv.END_DATE_ACTIVE   as CURRENCY_END_DATE
                     from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
                        , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv , AP_BANK_BRANCHES abb
                        , XX03_CURRENCIES_V xcv
                    where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
                      and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'N' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
                      and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
                      and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
                      and aba.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and aba.bank_branch_id = abb.bank_branch_id
                      and xcv.ENABLED_FLAG = 'Y' and xcv.CURRENCY_FLAG = 'Y' and aba.currency_code = xcv.CURRENCY_CODE
                   union all
                   select arm.NAME as NAME , xcv.CURRENCY_CODE as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
                         ,arm.START_DATE  as REC_START_DATE  ,arm.END_DATE  as REC_END_DATE
                         ,acrm.START_DATE as CUST_START_DATE ,acrm.END_DATE as CUST_END_DATE
                         ,hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
                         ,arma.start_date as ARMA_START_DATE , arma.end_date as ARMA_END_DATE
                         ,aba.inactive_date as ABA_INACTIVE_DATE , abb.end_date as ABB_END_DATE
                         ,xcv.START_DATE_ACTIVE as CURRENCY_START_DATE , xcv.END_DATE_ACTIVE as CURRENCY_END_DATE
                     from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
                        , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv , AP_BANK_BRANCHES abb
                        , XX03_CURRENCIES_V xcv
                    where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
                      and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'Y' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
                      and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
                      and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
                      and aba.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and aba.bank_branch_id = abb.bank_branch_id
                      and xcv.ENABLED_FLAG = 'Y' and xcv.CURRENCY_FLAG = 'Y'
                   ) x ,XX03_RECEIVABLE_SLIPS_IF xrsi
            where xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source 
              AND xrsi.CUSTOMER_NUMBER = x.CUSTOMER_NUMBER AND xrsi.LOCATION = x.LOCATION_NUMBER AND xrsi.RECEIPT_METHOD_NAME = x.NAME AND xrsi.CURRENCY_CODE = x.CURRENCY_CODE
              AND xrsi.INVOICE_DATE BETWEEN NVL(x.REC_START_DATE  ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(x.REC_END_DATE  ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
              AND xrsi.INVOICE_DATE BETWEEN NVL(x.CUST_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(x.CUST_END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
              AND xrsi.INVOICE_DATE BETWEEN nvl(x.ARMA_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND nvl(x.ARMA_END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
              AND xrsi.INVOICE_DATE <  nvl(x.ABA_INACTIVE_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
              AND xrsi.INVOICE_DATE <  nvl(x.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
              AND xrsi.INVOICE_DATE BETWEEN nvl(x.CURRENCY_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND nvl(x.CURRENCY_END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
           )                           xrml
         -- ver 11.5.10.2.10C Chg End
         -- ver 11.5.10.2.6 Chg End
-- 2012/10/24 Ver11.5.10.2.11 START
--         , XX03_COMMITMENT_NUMBER_LOV_V  xcnl
-- 2012/10/24 Ver11.5.10.2.11 END
         -- ver 11.5.10.2.10D Add Start
         ,(SELECT fc.CURRENCY_CODE CURRENCY_CODE ,xrsi.INTERFACE_ID INTERFACE_ID
             FROM FND_CURRENCIES fc ,XX03_RECEIVABLE_SLIPS_IF xrsi
            WHERE fc.ENABLED_FLAG  = 'Y' AND fc.CURRENCY_FLAG = 'Y' AND xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source AND xrsi.CURRENCY_CODE = fc.CURRENCY_CODE
              AND TRUNC(xrsi.INVOICE_DATE) BETWEEN NVL(fc.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD')) AND NVL(fc.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'))
           )                           xfc
         -- ver 11.5.10.2.10D Add End
        WHERE
              xrsi.REQUEST_ID               = h_request_id
          AND xrsi.SOURCE                   = h_source
          AND xrsi.SLIP_TYPE_NAME           = xstl.DESCRIPTION           (+)
          AND xrsi.REQUESTOR_PERSON_NUMBER  = xpp.EMPLOYEE_NUMBER        (+)
          AND xrsi.ENTRY_PERSON_NUMBER      = xpp2.EMPLOYEE_NUMBER       (+)
-- Ver11.5.10.1.5B Chg Start
          --AND xrsi.APPROVER_PERSON_NUMBER   = xapl.EMPLOYEE_NUMBER       (+)
          AND xrsi.APPROVER_PERSON_NUMBER   = ppf.EMPLOYEE_NUMBER     (+)
          AND TRUNC(SYSDATE) BETWEEN ppf.effective_start_date(+) AND ppf.effective_end_date(+)
          AND ppf.current_employee_flag(+) = 'Y'
-- Ver11.5.10.1.5B Chg End
          AND xrsi.CUSTOMER_NUMBER          = xacl.CUSTOMER_NUMBER       (+)
          AND xrsi.CUSTOMER_NUMBER          = xcsl.CUSTOMER_NUMBER       (+)
          AND xrsi.LOCATION                 = xcsl.LOCATION_NUMBER       (+)
          AND xrsi.CONVERSION_TYPE          = xct.USER_CONVERSION_TYPE   (+)
          AND xrsi.TERMS_NAME               = xtl.NAME                   (+)
          -- ver 11.5.10.2.6 Add Start
          AND xrsi.INTERFACE_ID             = xtl.INTERFACE_ID           (+)
          -- ver 11.5.10.2.6 Add End
          AND xrsi.TRANS_TYPE_NAME          = xttl.NAME                  (+)
          -- ver 11.5.10.2.6 Add Start
          AND xrsi.INTERFACE_ID             = xttl.INTERFACE_ID          (+)
          -- ver 11.5.10.2.6 Add End
          AND xrsi.CUSTOMER_NUMBER          = xrml.CUSTOMER_NUMBER       (+)
          AND xrsi.LOCATION                 = xrml.LOCATION_NUMBER       (+)
          AND xrsi.RECEIPT_METHOD_NAME      = xrml.NAME                  (+)
          AND xrsi.CURRENCY_CODE            = xrml.CURRENCY_CODE         (+)
          -- ver 11.5.10.2.6 Add Start
          AND xrsi.INTERFACE_ID             = xrml.INTERFACE_ID          (+)
          -- ver 11.5.10.2.6 Add End
-- 2012/10/24 Ver11.5.10.2.11 START
--          AND xrsi.COMMITMENT_NUMBER        = xcnl.TRX_NUMBER            (+)
-- 2012/10/24 Ver11.5.10.2.11 END
         -- ver 11.5.10.2.10D Add Start
          AND xrsi.CURRENCY_CODE            = xfc.CURRENCY_CODE          (+)
          AND xrsi.INTERFACE_ID             = xfc.INTERFACE_ID           (+)
         -- ver 11.5.10.2.10D Add End
        ) HEAD
      ,(SELECT /*+ USE_NL(xrsli) */ 
           xrsli.INTERFACE_ID          as INTERFACE_ID                       -- �C���^�[�t�F�[�XID
         , xrsli.LINE_NUMBER           as LINE_NUMBER                        -- ���C���i���o�[
         , xrsli.SLIP_LINE_TYPE_NAME   as SLIP_LINE_TYPE_NAME                -- �������e
         , xall.MEMO_LINE_ID           as SLIP_LINE_TYPE                     -- �������eID
         , xrsli.ENTERED_TAX_AMOUNT    as ENTERED_TAX_AMOUNT                 -- ���׏���Ŋz
         , xuoml.UOM_CODE              as SLIP_LINE_UOM                      -- �P��
         , xrsli.SLIP_LINE_UOM         as SLIP_LINE_UOM_NAME                 -- �P�ʖ�
         , xrsli.SLIP_LINE_UNIT_PRICE  as SLIP_LINE_UNIT_PRICE               -- �P��
         , xrsli.SLIP_LINE_QUANTITY    as SLIP_LINE_QUANTITY                 -- ����
         , xrsli.SLIP_LINE_ENTERED_AMOUNT  as SLIP_LINE_ENTERED_AMOUNT       -- ���͋��z
         , xrsli.SLIP_LINE_RECIEPT_NO  as SLIP_LINE_RECIEPT_NO               -- �[�i���ԍ�
         , xrsli.SLIP_DESCRIPTION      as SLIP_DESCRIPTION                   -- ���l�i���ׁj
         , xrsli.SLIP_LINE_TAX_FLAG    as SLIP_LINE_TAX_FLAG                 -- ����
         -- Ver11.5.10.1.5C 2005/10/21 Change Start
         --, xrsli.SLIP_LINE_TAX_CODE    as SLIP_LINE_TAX_CODE                 -- �ŋ敪
         , xtcl.TAX_CODE               as SLIP_LINE_TAX_CODE                 -- �ŋ敪
         -- Ver11.5.10.1.5C 2005/10/21 Change End
         , xtcl.TAX_TYPE               as TAX_NAME                           -- �ŋ敪��
         , xtcl.VAT_TAX_ID             as VAT_TAX_ID                         -- �ŋ敪ID
         -- Ver11.5.10.1.5C 2005/10/21 Add Start
         , xtcl.AMOUNT_INCLUDES_TAX_FLAG  as MST_TAX_FLAG                    -- �ŋ敪�̓��Ńt���O
         -- Ver11.5.10.1.5C 2005/10/21 Add End
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
         , xbtl.BUSINESS_TYPES_COL     as SEGMENT6_NAME                      -- ���Ƌ敪��
         , xprl.FLEX_VALUE             as SEGMENT7                           -- �v���W�F�N�g
         , xprl.PROJECTS_COL           as SEGMENT7_NAME                      -- �v���W�F�N�g��
         , xfl.FLEX_VALUE              as SEGMENT8                           -- �\���P
         , xfl.FUTURES_COL             as SEGMENT8_NAME                      -- �\��
         , xrsli.INCR_DECR_REASON_CODE as INCR_DECR_REASON_CODE              -- �������R
         , xidrl.INCR_DECR_REASONS_COL as INCR_DECR_REASON_NAME              -- �������R��
         , xrsli.RECON_REFERENCE       as RECON_REFERENCE                    -- �����Q��
         , xrsli.JOURNAL_DESCRIPTION   as JOURNAL_DESCRIPTION                -- ���l�i���ׁj
         , xrsli.ORG_ID                as ORG_ID                             -- �I���OID
-- == 2016/12/06 11.5.10.2.12 Added START ===============================================================
         , xrsli.ATTRIBUTE7            as ATTRIBUTE7                         -- �g�c���ٔԍ�
-- == 2016/12/06 11.5.10.2.12 Added END   ===============================================================
         , xrsli.CREATED_BY            as CREATED_BY
         , xrsli.CREATION_DATE         as CREATION_DATE
         , xrsli.LAST_UPDATED_BY       as LAST_UPDATED_BY
         , xrsli.LAST_UPDATE_DATE      as LAST_UPDATE_DATE
         , xrsli.LAST_UPDATE_LOGIN     as LAST_UPDATE_LOGIN
         , xrsli.REQUEST_ID            as REQUEST_ID
         , xrsli.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
         , xrsli.PROGRAM_ID            as PROGRAM_ID
         , xrsli.PROGRAM_UPDATE_DATE   as PROGRAM_UPDATE_DATE
        FROM
         -- 2005/12/27 Ver11.5.10.1.6B Change Start
         -- XX03_RECEIVABLE_SLIPS_LINE_IF  xrsli
         -- ver 11.5.10.2.6 Chg Start
         --  XX03_RECEIVABLE_SLIPS_IF       xrsi
         --, XX03_RECEIVABLE_SLIPS_LINE_IF  xrsli
           XX03_RECEIVABLE_SLIPS_LINE_IF  xrsli
         -- ver 11.5.10.2.6 Chg End
         -- 2005/12/27 Ver11.5.10.1.6B Change End
         -- ver 11.5.10.2.6 Chg Start
         --, XX03_TAX_CLASS_LOV_V        xtcl
         ,(SELECT xtclv.TAX_CODE ,xtclv.TAX_TYPE ,xtclv.VAT_TAX_ID ,xtclv.AMOUNT_INCLUDES_TAX_FLAG
                 ,xrsli.INTERFACE_ID ,xrsli.LINE_NUMBER
           FROM XX03_TAX_CLASS_LOV_V xtclv ,XX03_RECEIVABLE_SLIPS_IF xrsi ,XX03_RECEIVABLE_SLIPS_LINE_IF xrsli
           WHERE xrsli.SLIP_LINE_TAX_CODE = xtclv.TAX_CODE AND xrsi.INTERFACE_ID = xrsli.INTERFACE_ID
             AND xrsi.INVOICE_DATE BETWEEN NVL(xtclv.START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(xtclv.END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
             AND xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source AND xrsli.REQUEST_ID = h_request_id AND xrsli.SOURCE = h_source
           )                           xtcl
         -- ver 11.5.10.2.6 Chg End
         -- ver 11.5.10.2.9B Chg Start
         --,(SELECT amlv.NAME , amlv.MEMO_LINE_ID
         --  FROM AR_MEMO_LINES_VL amlv , XX03_SLIP_TYPES_V xstv
         --  WHERE TRUNC(SYSDATE) BETWEEN amlv.START_DATE AND NVL(amlv.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD')) AND amlv.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND amlv.ATTRIBUTE1 = xstv.LOOKUP_CODE
         --    AND xstv.ENABLED_FLAG = 'Y' AND xstv.ATTRIBUTE14 = 'AR'
         --    AND EXISTS (SELECT '1' FROM XX03_FLEX_VALUE_CHILDREN XFVC , XX03_PER_PEOPLES_V XPPV
         --                WHERE XPPV.USER_ID = XX00_PROFILE_PKG.VALUE('USER_ID') AND amlv.ATTRIBUTE2 = XFVC.PARENT_FLEX_VALUE AND XFVC.FLEX_VALUE = XPPV.ATTRIBUTE28)
         --  )                           xall
         ,(SELECT amlv.NAME , amlv.MEMO_LINE_ID , xrsli.INTERFACE_ID , xrsli.LINE_NUMBER
           FROM AR_MEMO_LINES_VL amlv , XX03_SLIP_TYPES_LOV_V xstlv , XX03_RECEIVABLE_SLIPS_IF xrsi , XX03_RECEIVABLE_SLIPS_LINE_IF xrsli
           WHERE xrsli.SLIP_LINE_TYPE_NAME = amlv.NAME AND xrsi.INVOICE_DATE BETWEEN amlv.START_DATE AND NVL(amlv.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
             AND amlv.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND amlv.ATTRIBUTE1 = xstlv.LOOKUP_CODE AND xrsi.SLIP_TYPE_NAME = xstlv.DESCRIPTION AND xstlv.ATTRIBUTE14 = 'AR'
             AND xrsi.INTERFACE_ID = xrsli.INTERFACE_ID AND xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source AND xrsli.REQUEST_ID = h_request_id AND xrsli.SOURCE = h_source
           )                           xall
         -- ver 11.5.10.2.9B Chg End
         , XX03_UNITS_OF_MERSURE_LOV_V  xuoml
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
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'  AND XV.ATTRIBUTE4 IS NOT NULL
           )                           xal
         ,(SELECT XV.PARENT_FLEX_VALUE_LOW,XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION SUB_ACCOUNTS_COL
           FROM XX03_SUB_ACCOUNTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xsal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION PARTNERS_COL
           FROM XX03_PARTNERS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xpal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION BUSINESS_TYPES_COL
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
        WHERE
              xrsli.REQUEST_ID              = h_request_id
          AND xrsli.SOURCE                  = h_source
          AND xrsli.SLIP_LINE_TAX_CODE      = xtcl.TAX_CODE              (+)
          -- 2005/12/27 Ver11.5.10.1.6B Add Start
          -- ver 11.5.10.2.6 Del Start
          ---- ver 11.5.10.2.5B Add Start
          --AND xrsi.REQUEST_ID               = h_request_id
          --AND xrsi.SOURCE                   = h_source
          ---- ver 11.5.10.2.5B Add End
          --AND xrsi.INTERFACE_ID             = xrsli.INTERFACE_ID
          -- ver 11.5.10.2.6 Del End
          -- ver 11.5.10.2.6 Chg Start
          --AND xrsi.INVOICE_DATE BETWEEN xtcl.START_DATE
          --                          AND NVL(xtcl.END_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD'))
          AND xrsli.INTERFACE_ID            = xtcl.INTERFACE_ID          (+)
          AND xrsli.LINE_NUMBER             = xtcl.LINE_NUMBER           (+)
          -- ver 11.5.10.2.6 Chg End
          -- 2005/12/27 Ver11.5.10.1.6B Add End
          AND xrsli.SLIP_LINE_TYPE_NAME     = xall.NAME                  (+)
          -- ver 11.5.10.2.9B Add Start
          AND xrsli.INTERFACE_ID            = xall.INTERFACE_ID          (+)
          AND xrsli.LINE_NUMBER             = xall.LINE_NUMBER           (+)
          -- ver 11.5.10.2.9B Add End
          AND xrsli.SLIP_LINE_UOM           = xuoml.UNIT_OF_MEASURE      (+)
          AND xrsli.SEGMENT1                = xcl.FLEX_VALUE             (+)
          AND xrsli.SEGMENT2                = xdl.FLEX_VALUE             (+)
          AND xrsli.SEGMENT3                = xal.FLEX_VALUE             (+)
          AND xrsli.SEGMENT3                = xsal.PARENT_FLEX_VALUE_LOW (+)
          AND xrsli.SEGMENT4                = xsal.FLEX_VALUE            (+)
          AND xrsli.SEGMENT5                = xpal.FLEX_VALUE            (+)
          AND xrsli.SEGMENT6                = xbtl.FLEX_VALUE            (+)
          AND xrsli.SEGMENT7                = xprl.FLEX_VALUE            (+)
          AND xrsli.SEGMENT8                = xfl.FLEX_VALUE             (+)
          AND xrsli.SEGMENT3                = xidrl.PARENT_FLEX_VALUE_LOW  (+)
          AND xrsli.INCR_DECR_REASON_CODE   = xidrl.FLEX_VALUE           (+)
        ) LINE
      ,(SELECT /*+ USE_NL(xrsic) */ 
               xrsic.INTERFACE_ID         as INTERFACE_ID
             , COUNT(xrsic.INTERFACE_ID)  as REC_COUNT
        FROM   XX03_RECEIVABLE_SLIPS_IF xrsic
        WHERE  xrsic.REQUEST_ID = h_request_id
          AND  xrsic.SOURCE     = h_source
        GROUP BY xrsic.INTERFACE_ID
        ) CNT
      -- ver 11.5.10.2.6B Add Start
      ,(SELECT /*+ USE_NL(xrsli) */ 
               DISTINCT(xrsi.INTERFACE_ID)  as INTERFACE_ID
             , 'X'                          as LINE_SUM_NO_FLG
        FROM   XX03_RECEIVABLE_SLIPS_IF  xrsi
        WHERE  xrsi.REQUEST_ID = h_request_id
          AND  xrsi.SOURCE     = h_source
          AND  EXISTS (SELECT '1'
                       FROM   XX03_RECEIVABLE_SLIPS_LINE_IF  xrsli
                       WHERE  xrsli.REQUEST_ID  = h_request_id
                         AND  xrsli.SOURCE      = h_source
                         AND  xrsli.INTERFACE_ID = xrsi.INTERFACE_ID
                       GROUP BY INTERFACE_ID , LINE_NUMBER
                       HAVING COUNT(xrsli.LINE_NUMBER) > 1
                       )
        ) CNT2
      -- ver 11.5.10.2.6B Add End
      -- ver 11.5.10.2.10F Add Start
      ,(SELECT /*+ USE_NL(xrsi) */ 
           xrsi.INTERFACE_ID as INTERFACE_ID
          ,ppf.PERSON_ID     as PERSON_ID
        FROM
           XX03_RECEIVABLE_SLIPS_IF    xrsi
         ,(SELECT employee_number ,person_id FROM PER_PEOPLE_F
           WHERE current_employee_flag = 'Y' AND TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date
           ) ppf
        WHERE
              xrsi.APPROVER_PERSON_NUMBER = ppf.EMPLOYEE_NUMBER
          AND EXISTS (SELECT '1'
                      FROM   XX03_APPROVER_PERSON_LOV_V xaplv
                      WHERE  xaplv.PERSON_ID = ppf.person_id
                        AND (   xaplv.PROFILE_VAL_DEP = 'ALL'
                             or xaplv.PROFILE_VAL_DEP = 'AR')
                      )
        ) APPROVER
      -- ver 11.5.10.2.10F Add End
    WHERE
          HEAD.INTERFACE_ID = LINE.INTERFACE_ID
      AND HEAD.INTERFACE_ID = CNT.INTERFACE_ID
      -- ver 11.5.10.2.6B Add Start
      AND HEAD.INTERFACE_ID = CNT2.INTERFACE_ID(+)
      -- ver 11.5.10.2.6B Add End
      -- ver 11.5.10.2.10F Add Start
      AND HEAD.INTERFACE_ID = APPROVER.INTERFACE_ID(+)
      -- ver 11.5.10.2.10F Add End
    ORDER BY
       HEAD.INTERFACE_ID ,LINE.LINE_NUMBER
    ;
--
    -- �w�b�_���׏��J�[�\�����R�[�h�^
    xx03_if_head_line_rec  xx03_if_head_line_cur%ROWTYPE;
--
-- Ver11.5.10.1.5 2005/09/05 Add End
--
  --  ����Ōv�Z���x���E����Œ[������ �V�X�e�����J�[�\��
  CURSOR sys_tax_cur
  IS
    SELECT
      TAX_ROUNDING_ALLOW_OVERRIDE      as TAX_ROUNDING_ALLOW_OVERRIDE,
      TAX_HEADER_LEVEL_FLAG            as TAX_HEADER_LEVEL_FLAG,
      SUBSTRB(TAX_ROUNDING_RULE, 1, 1) as TAX_ROUNDING_RULE
    FROM
      AR_SYSTEM_PARAMETERS
  ;
--
  --  ����Ōv�Z���x���E����Œ[������ �V�X�e�����J�[�\�����R�[�h�^
  sys_tax_rec    sys_tax_cur%ROWTYPE;
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  same_id_header_expt      EXCEPTION;     -- �w�b�_���R�[�h�d������
  get_slip_type_expt       EXCEPTION;     -- �`�[��ʓ��͒l�Ȃ�
  get_approver_expt        EXCEPTION;     -- ���F�ғ��͒l�Ȃ�
  get_invoice_date_expt    EXCEPTION;     -- ���������t���͒l�Ȃ�
  get_gl_date_expt         EXCEPTION;     -- �v������͒l�Ȃ�
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
    cv_prof_ORG_ID CONSTANT VARCHAR2(20) := 'ORG_ID';           -- �I���OID�̎擾�p�L�[�l
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
                        xx00_profile_pkg.value(cv_prof_GL_ID),       -- ��v����ID
                        TO_NUMBER(xx00_profile_pkg.value(cv_prof_ORG_ID)),  -- �I���OID
                        xx00_global_pkg.conc_program_id,                    -- �R���J�����g�v���O����ID
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
--    ln_line_id     NUMBER;  -- ����ID
--    ln_line_count  NUMBER;  -- ���טA��
--    ln_amount      NUMBER;  -- ���z
--    ln_ent_amount  NUMBER;  -- ���z
--    ln_segment3    VARCHAR2(150);  --����Ȗ�ID
----
--    -- ===============================
--    -- ���[�J���E�J�[�\��
--    -- ===============================
--    -- ���׏��J�[�\��
--    CURSOR xx03_if_detail_cur(h_source        VARCHAR2,
--                              h_request_id    NUMBER,
--                              h_interface_id  NUMBER,
--                              h_currency_code VARCHAR2)
--    IS
--      SELECT
--          xrsli.INTERFACE_ID             as INTERFACE_ID                        -- �C���^�[�t�F�[�XID
--        , xrsli.SLIP_LINE_TYPE_NAME      as SLIP_LINE_TYPE_NAME                 -- �������e
--        , xall.MEMO_LINE_ID              as SLIP_LINE_TYPE                      -- �������eID
--        , xrsli.ENTERED_TAX_AMOUNT       as ENTERED_TAX_AMOUNT                  -- ���׏���Ŋz
--        , xuoml.UOM_CODE                 as SLIP_LINE_UOM                       -- �P��
--        , xrsli.SLIP_LINE_UOM            as SLIP_LINE_UOM_NAME                  -- �P�ʖ�
--        , xrsli.SLIP_LINE_UNIT_PRICE     as SLIP_LINE_UNIT_PRICE                -- �P��
--        , xrsli.SLIP_LINE_QUANTITY       as SLIP_LINE_QUANTITY                  -- ����
--        , xrsli.SLIP_LINE_ENTERED_AMOUNT as SLIP_LINE_ENTERED_AMOUNT            -- ���͋��z
--        , xrsli.SLIP_LINE_RECIEPT_NO     as SLIP_LINE_RECIEPT_NO                -- �[�i���ԍ�
--        , xrsli.SLIP_DESCRIPTION         as SLIP_DESCRIPTION                    -- ���l�i���ׁj
--        , xrsli.SLIP_LINE_TAX_FLAG       as SLIP_LINE_TAX_FLAG                  -- ����
--        , xrsli.SLIP_LINE_TAX_CODE       as SLIP_LINE_TAX_CODE                  -- �ŋ敪
--        , xtcl.TAX_TYPE                  as TAX_NAME                            -- �ŋ敪��
--        , xrsli.SEGMENT1                 as SEGMENT1                            -- ���
--        , xrsli.SEGMENT2                 as SEGMENT2                            -- ����
--        , xrsli.SEGMENT3                 as SEGMENT3                            -- ����Ȗ�
--        , xrsli.SEGMENT4                 as SEGMENT4                            -- �⏕�Ȗ�
--        , xrsli.SEGMENT5                 as SEGMENT5                            -- �����
--        , xrsli.SEGMENT6                 as SEGMENT6                            -- ���Ƌ敪
--        , xrsli.SEGMENT7                 as SEGMENT7                            -- �v���W�F�N�g
--        , xrsli.SEGMENT8                 as SEGMENT8                            -- �\���P
--        , xcl.COMPANIES_COL              as SEGMENT1_NAME                       -- ��Ж�
--        , xdl.DEPARTMENTS_COL            as SEGMENT2_NAME                       -- ���喼
--        , xal.ACCOUNTS_COL               as SEGMENT3_NAME                       -- ����Ȗږ�
--        , xsal.SUB_ACCOUNTS_COL          as SEGMENT4_NAME                       -- �⏕�Ȗږ�
--        , xpal.PARTNERS_COL              as SEGMENT5_NAME                       -- ����於
--        , xbtl.BUSINESS_TYPES_COL        as SEGMENT6_NAME                       -- ���Ƌ敪��
--        , xprl.PROJECTS_COL              as SEGMENT7_NAME                       -- �v���W�F�N�g��
--        , xfl.FUTURES_COL                as SEGMENT8_NAME                       -- �\��
--        , xrsli.INCR_DECR_REASON_CODE    as INCR_DECR_REASON_CODE               -- �������R
--        , xidrl.INCR_DECR_REASONS_COL    as INCR_DECR_REASON_NAME               -- �������R��
--        , xrsli.RECON_REFERENCE          as RECON_REFERENCE                     -- �����Q��
--        , xrsli.JOURNAL_DESCRIPTION      as JOURNAL_DESCRIPTION                 -- ���l�i���ׁj
--        , xrsli.ORG_ID                   as ORG_ID                              -- �I���OID
--        , xrsli.CREATED_BY
--        , xrsli.CREATION_DATE
--        , xrsli.LAST_UPDATED_BY
--        , xrsli.LAST_UPDATE_DATE
--        , xrsli.LAST_UPDATE_LOGIN
--        , xrsli.REQUEST_ID
--        , xrsli.PROGRAM_APPLICATION_ID
--        , xrsli.PROGRAM_ID
--        , xrsli.PROGRAM_UPDATE_DATE
--      FROM
--          XX03_RECEIVABLE_SLIPS_LINE_IF xrsli
--        , XX03_TAX_CLASS_LOV_V          xtcl
--        , XX03_COMPANIES_LOV_V          xcl
--        , XX03_DEPARTMENTS_LOV_V        xdl
----Ver11.5.10.1.4 2005/08/15 CHANGE START
--        --, XX03_ACCOUNTS_ALL_LOV_V    xal
--        , XX03_AR_ACCOUNTS_ALL_LOV_V    xal
----Ver11.5.10.1.4 2005/08/15 CHANGE END
--        , XX03_SUB_ACCOUNTS_LOV_V       xsal
--        , XX03_PARTNERS_LOV_V           xpal
--        , XX03_BUSINESS_TYPES_LOV_V     xbtl
--        , XX03_PROJECTS_LOV_V           xprl
--        , XX03_INCR_DECR_REASONS_LOV_V  xidrl
--        , XX03_FUTURES_LOV_V            xfl
--        , XX03_AR_LINES_LOV_V           xall
--        , XX03_UNITS_OF_MERSURE_LOV_V   xuoml
--      WHERE
--            xrsli.REQUEST_ID            = h_request_id
--        AND xrsli.SOURCE                = h_source
--        AND xrsli.INTERFACE_ID          = h_interface_id
--        AND xrsli.SLIP_LINE_TAX_CODE    = xtcl.TAX_CODE               (+)
--        AND xrsli.SEGMENT1              = xcl.FLEX_VALUE              (+)
--        AND xrsli.SEGMENT2              = xdl.FLEX_VALUE              (+)
--        AND xrsli.SEGMENT3              = xal.FLEX_VALUE              (+)
--        AND xrsli.SEGMENT4              = xsal.FLEX_VALUE             (+)
--        AND xrsli.SEGMENT3              = xsal.PARENT_FLEX_VALUE_LOW  (+)
--        AND xrsli.SEGMENT5              = xpal.FLEX_VALUE             (+)
--        AND xrsli.SEGMENT6              = xbtl.FLEX_VALUE             (+)
--        AND xrsli.SEGMENT7              = xprl.FLEX_VALUE             (+)
--        AND xrsli.SEGMENT8              = xfl.FLEX_VALUE              (+)
--        AND xrsli.INCR_DECR_REASON_CODE = xidrl.FLEX_VALUE            (+)
--        AND xrsli.SEGMENT3              = xidrl.PARENT_FLEX_VALUE_LOW (+)
--        AND xrsli.SLIP_LINE_TYPE_NAME   = xall.NAME                   (+)
--        AND xrsli.SLIP_LINE_UOM         = xuoml.UNIT_OF_MEASURE       (+)
--      ORDER BY
--        xrsli.LINE_NUMBER;
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
--    -- ���טA�ԏ�����
--    ln_line_count := 1;
--    -- ���׏��J�[�\���I�[�v��
--    OPEN xx03_if_detail_cur(iv_source,
--                            in_request_id,
--                            xx03_if_header_rec.INTERFACE_ID,
--                            xx03_if_header_rec.INVOICE_CURRENCY_CODE);
--    <<xx03_if_detail_loop>>
--    LOOP
--      FETCH xx03_if_detail_cur INTO xx03_if_detail_rec;
--      IF xx03_if_detail_cur%NOTFOUND THEN
--        -- �Ώۃf�[�^���Ȃ��Ȃ�܂Ń��[�v
--        EXIT xx03_if_detail_loop;
--      END IF;
----
--      -- ����ID�擾
--      SELECT XX03_RECEIVABLE_SLIPS_LINE_S.nextval
--        INTO ln_line_id
--        FROM dual;
----
--      -- �E�v���̎擾
----    BEGIN
----      SELECT xsltl.SLIP_LINE_TYPES_COL as SLIP_LINE_TYPE_NAME
----        INTO lv_slip_type_name
----        FROM XX03_SLIP_LINE_TYPES_LOV_V xsltl
----       WHERE xsltl.LOOKUP_CODE = xx03_if_detail_rec.SLIP_LINE_TYPE
----         AND xsltl.VENDOR_SITE_ID = xx03_if_header_rec.VENDOR_SITE_ID;
----    EXCEPTION
----      WHEN NO_DATA_FOUND THEN
----        -- �Ώۃf�[�^�Ȃ����͓E�v���̋�
----        lv_slip_type_name := '';
----        -- �X�e�[�^�X���G���[��
----        gv_result := cv_result_error;
----        -- �G���[�������Z
----        gn_error_count := gn_error_count + 1;
----        xx00_file_pkg.output(
----          xx00_message_pkg.get_msg(
----            'XX03',
----            'APP-XX03-08026',
----            'TOK_XX03_LINE_NUMBER',
----            ln_line_count
----          )
----        );
----    END;
----
--    -- �������eID�`�F�b�N
--    IF ( xx03_if_detail_rec.SLIP_LINE_TYPE IS NULL ) THEN
--      -- �������eID����̏ꍇ�͐������e���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08032'
--        )
--      );
--    END IF;
--
--    -- 2005.04.22 add start Ver11.5.10.1.1
--    -- �P�ʃ`�F�b�N
--    -- 2005.04.27 change start Ver11.5.10.1.1
--    -- IF ( xx03_if_detail_rec.SLIP_LINE_UOM IS NULL ) THEN
--      -- �P�ʂ���̏ꍇ�͒P�ʓ��̓G���[�\��
--    IF ( xx03_if_detail_rec.SLIP_LINE_UOM IS NULL ) AND
--      ( xx03_if_detail_rec.SLIP_LINE_UOM_NAME IS NOT NULL ) THEN
--      -- �P�ʂ���ŒP�ʖ�����łȂ��ꍇ�͒P�ʓ��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08044'
--        )
--      );
--    END IF;
--    -- 2005.04.27 change end Ver11.5.10.1.1
--    -- 2005.04.22 add end Ver11.5.10.1.1
--
------
----    -- ���ז{�̋��z�`�F�b�N
----    IF ( xx03_if_detail_rec.ENTERED_ITEM_AMOUNT IS NULL ) THEN
----      -- �{�̋��z����̏ꍇ�͖{�̋��z���̓G���[�\��
----      -- �X�e�[�^�X���G���[��
----      gv_result := cv_result_error;
----      -- �G���[�������Z
----      gn_error_count := gn_error_count + 1;
----      xx00_file_pkg.output(
----        xx00_message_pkg.get_msg(
----          'XX03',
----          'APP-XX03-08033'
----        )
----      );
----    END IF;
----
--    -- ���׏���Ŋz�`�F�b�N
--    IF ( xx03_if_detail_rec.ENTERED_TAX_AMOUNT IS NULL ) THEN
--      -- ����Ŋz����̏ꍇ�͏���Ŋz���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08034'
--        )
--      );
--    END IF;
----
--    -- �ŋ敪�`�F�b�N
--    IF ( xx03_if_detail_rec.SLIP_LINE_TAX_CODE IS NULL
--           OR TRIM(xx03_if_detail_rec.SLIP_LINE_TAX_CODE) = '' ) THEN
--      -- �ŋ敪����̏ꍇ�͐ŋ敪���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08035'
--        )
--      );
--    END IF;
----
--    -- ��Ѓ`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT1 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT1) = '' ) THEN
--      -- ��Ђ���̏ꍇ�͉�Г��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08036'
--        )
--      );
--    END IF;
----
--    -- ����`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT2 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT2) = '' ) THEN
--      -- ���傪��̏ꍇ�͕�����̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08037'
--        )
--      );
--    END IF;
----
--    -- ����Ȗڃ`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT3 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT3) = '' ) THEN
--      -- ����Ȗڂ���������͕s���̏ꍇ�͊���Ȗړ��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08038'
--        )
--      );
--    ELSE
--    -- ����Ȗڂ���łȂ��Ƃ��́A���͂��ꂽ����Ȗڂ�����Ȗڂ�
--    -- view�ɑ��݂��邩���`�F�b�N����
--      BEGIN
--        SELECT xal.FLEX_VALUE as SEGMENT3
--          INTO ln_segment3
--          FROM XX03_AR_ACCOUNTS_ALL_LOV_V    xal
--         WHERE xal.FLEX_VALUE = xx03_if_detail_rec.SEGMENT3;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- �Ώۃf�[�^�Ȃ����͊���Ȗږ��̋�
--          ln_segment3 := '';
--          -- �X�e�[�^�X���G���[��
--          gv_result := cv_result_error;
--          -- �G���[�������Z
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08038'
--            )
--          );
--      END;
--  END IF;
----
--    -- �⏕�Ȗڃ`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT4 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT4) = '' ) THEN
--      -- ����Ȗڂ���̏ꍇ�͊���Ȗړ��̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08039'
--        )
--      );
--    END IF;
----
--    -- �����`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT5 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT5) = '' ) THEN
--      -- ����悪��̏ꍇ�͑������̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08040'
--        )
--      );
--    END IF;
----
--    -- ���Ƌ敪�`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT6 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT6) = '' ) THEN
--      -- ���Ƌ敪����̏ꍇ�͎��Ƌ敪���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08041'
--        )
--      );
--    END IF;
----
--    -- �v���W�F�N�g�`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT7 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT7) = '' ) THEN
--      -- �v���W�F�N�g����̏ꍇ�̓v���W�F�N�g���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08042'
--        )
--      );
--    END IF;
----
--    -- �\���`�F�b�N
--    IF ( xx03_if_detail_rec.SEGMENT8 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT8) = '' ) THEN
--      -- �\������̏ꍇ�͗\�����̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08043'
--        )
--      );
--    END IF;
----
--      -- ���͋��z�Z�o
--      -- ���͋��z���P��������
--      ln_amount  :=  xx03_if_detail_rec.SLIP_LINE_UNIT_PRICE * xx03_if_detail_rec.SLIP_LINE_QUANTITY;
--      -- '����'��'Y'�̎�
--      IF ( xx03_if_detail_rec.SLIP_LINE_TAX_FLAG = cv_yes ) THEN
--        -- �{�̋��z�����͋��z�|����Ŋz
--        ln_ent_amount  :=  ln_amount - xx03_if_detail_rec.ENTERED_TAX_AMOUNT;
--      -- '����'��'N'�̎�
--      ELSIF  ( xx03_if_detail_rec.SLIP_LINE_TAX_FLAG = cv_no ) THEN
--        -- �{�̋��z�����͋��z
--        ln_ent_amount  :=  ln_amount;
--      -- ����ȊO�̎�
--      ELSE
--        -- ���œ��͒l�G���[
--        ln_ent_amount := 0;
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
--      INSERT INTO XX03_RECEIVABLE_SLIPS_LINE(
--          RECEIVABLE_LINE_ID             -- ����ID
--        , RECEIVABLE_ID                  -- �`�[ID
--        , LINE_NUMBER                    -- No
--        , SLIP_LINE_TYPE                 -- �������eID
--        , SLIP_LINE_TYPE_NAME            -- �������e
--        , SLIP_LINE_UOM                  -- �P��
--        , SLIP_LINE_UOM_NAME             -- �P�ʖ�
--        , SLIP_LINE_UNIT_PRICE           -- �P��
--        , SLIP_LINE_QUANTITY             -- ����
--        , SLIP_LINE_ENTERED_AMOUNT       -- ���͋��z
--        , TAX_CODE                       -- �ŋ敪ID
--        , TAX_NAME                       -- �ŋ敪
--        , AMOUNT_INCLUDES_TAX_FLAG       -- ����
--        , ENTERED_ITEM_AMOUNT            -- �{�̋��z
--        , ENTERED_TAX_AMOUNT             -- ����Ŋz
--        , ACCOUNTED_AMOUNT               -- ���Z�ϋ��z
--        , SLIP_LINE_RECIEPT_NO           -- �[�i���ԍ�
--        , SLIP_DESCRIPTION               -- ���l�i���ׁj
--        , SEGMENT1                       -- ���
--        , SEGMENT2                       -- ����
--        , SEGMENT3                       -- ����Ȗ�
--        , SEGMENT4                       -- �⏕�Ȗ�
--        , SEGMENT5                       -- �����
--        , SEGMENT6                       -- ���Ƌ敪
--        , SEGMENT7                       -- �v���W�F�N�g
--        , SEGMENT8                       -- �\���P
--        , SEGMENT9
--        , SEGMENT10
--        , SEGMENT11
--        , SEGMENT12
--        , SEGMENT13
--        , SEGMENT14
--        , SEGMENT15
--        , SEGMENT16
--        , SEGMENT17
--        , SEGMENT18
--        , SEGMENT19
--        , SEGMENT20
--        , SEGMENT1_NAME
--        , SEGMENT2_NAME
--        , SEGMENT3_NAME
--        , SEGMENT4_NAME
--        , SEGMENT5_NAME
--        , SEGMENT6_NAME
--        , SEGMENT7_NAME
--        , SEGMENT8_NAME
--        , INCR_DECR_REASON_CODE          -- �������R
--        , INCR_DECR_REASON_NAME          -- �������R��
--        , RECON_REFERENCE                -- �����Q��
--        , JOURNAL_DESCRIPTION            -- ���l�i�d��j
--        , ORG_ID                         -- �I���OID
--        , ATTRIBUTE_CATEGORY
--        , ATTRIBUTE1
--        , ATTRIBUTE2
--        , ATTRIBUTE3
--        , ATTRIBUTE4
--        , ATTRIBUTE5
--        , ATTRIBUTE6
--        , ATTRIBUTE7
--        , ATTRIBUTE8
--        , ATTRIBUTE9
--        , ATTRIBUTE10
--        , ATTRIBUTE11
--        , ATTRIBUTE12
--        , ATTRIBUTE13
--        , ATTRIBUTE14
--        , ATTRIBUTE15
--        , CREATED_BY
--        , CREATION_DATE
--        , LAST_UPDATED_BY
--        , LAST_UPDATE_DATE
--        , LAST_UPDATE_LOGIN
--        , REQUEST_ID
--        , PROGRAM_APPLICATION_ID
--        , PROGRAM_ID
--        , PROGRAM_UPDATE_DATE
--      )
--      VALUES(
--          ln_line_id                                        -- ����ID
--        , gn_receivable_id                                  -- �`�[ID
--        , ln_line_count                                     -- No
--        , xx03_if_detail_rec.SLIP_LINE_TYPE                 -- �������eID
--        , xx03_if_detail_rec.SLIP_LINE_TYPE_NAME            -- �������e
--        , xx03_if_detail_rec.SLIP_LINE_UOM                  -- �P��
--        , xx03_if_detail_rec.SLIP_LINE_UOM_NAME             -- �P��
--        , xx03_if_detail_rec.SLIP_LINE_UNIT_PRICE           -- �P��
--        , xx03_if_detail_rec.SLIP_LINE_QUANTITY             -- ����
--        , ln_amount                                         -- ���͋��z
--        , xx03_if_detail_rec.SLIP_LINE_TAX_CODE             -- �ŋ敪ID
--        , xx03_if_detail_rec.TAX_NAME                       -- �ŋ敪
--        , xx03_if_detail_rec.SLIP_LINE_TAX_FLAG             -- ����
--        , ln_ent_amount                                     -- �{�̋��z
--        , xx03_if_detail_rec.ENTERED_TAX_AMOUNT             -- ����Ŋz
--        , 0                                                 -- ���Z�ϋ��z
--        , xx03_if_detail_rec.SLIP_LINE_RECIEPT_NO           -- �[�i���ԍ�
--        , xx03_if_detail_rec.SLIP_DESCRIPTION               -- ���l�i���ׁj
--        , xx03_if_detail_rec.SEGMENT1                       -- ���
--        , xx03_if_detail_rec.SEGMENT2                       -- ����
--        , xx03_if_detail_rec.SEGMENT3                       -- ����Ȗ�
--        , xx03_if_detail_rec.SEGMENT4                       -- �⏕�Ȗ�
--        , xx03_if_detail_rec.SEGMENT5                       -- �����
--        , xx03_if_detail_rec.SEGMENT6                       -- ���Ƌ敪
--        , xx03_if_detail_rec.SEGMENT7                       -- �v���W�F�N�g
--        , xx03_if_detail_rec.SEGMENT8                       -- �\���P
--        , NULL                                              -- SEGMENT9
--        , NULL                                              -- SEGMENT10
--        , NULL                                              -- SEGMENT11
--        , NULL                                              -- SEGMENT12
--        , NULL                                              -- SEGMENT13
--        , NULL                                              -- SEGMENT14
--        , NULL                                              -- SEGMENT15
--        , NULL                                              -- SEGMENT16
--        , NULL                                              -- SEGMENT17
--        , NULL                                              -- SEGMENT18
--        , NULL                                              -- SEGMENT19
--        , NULL                                              -- SEGMENT20
--        , xx03_if_detail_rec.SEGMENT1_NAME                  -- ��Ж�
--        , xx03_if_detail_rec.SEGMENT2_NAME                  -- ���喼
--        , xx03_if_detail_rec.SEGMENT3_NAME                  -- ����Ȗږ�
--        , xx03_if_detail_rec.SEGMENT4_NAME                  -- �⏕�Ȗږ�
--        , xx03_if_detail_rec.SEGMENT5_NAME                  -- ����於
--        , xx03_if_detail_rec.SEGMENT6_NAME                  -- ���Ƌ敪��
--        , xx03_if_detail_rec.SEGMENT7_NAME                  -- �v���W�F�N�g��
--        , xx03_if_detail_rec.SEGMENT8_NAME                  -- �\���P
--        , xx03_if_detail_rec.INCR_DECR_REASON_CODE          -- �������R
--        , xx03_if_detail_rec.INCR_DECR_REASON_NAME          -- �������R��
--        , xx03_if_detail_rec.RECON_REFERENCE                -- �����Q��
--        , xx03_if_detail_rec.JOURNAL_DESCRIPTION            -- ���l�i�d��j
--        , xx03_if_detail_rec.ORG_ID                         -- �I���OID
--        , NULL                                              -- ATTRIBUTE_CATEGORY
--        , NULL                                              -- ATTRIBUTE1
--        , NULL                                              -- ATTRIBUTE2
--        , NULL                                              -- ATTRIBUTE3
--        , NULL                                              -- ATTRIBUTE4
--        , NULL                                              -- ATTRIBUTE5
--        , NULL                                              -- ATTRIBUTE6
--        , NULL                                              -- ATTRIBUTE7
--        , NULL                                              -- ATTRIBUTE8
--        , NULL                                              -- ATTRIBUTE9
--        , NULL                                              -- ATTRIBUTE10
--        , NULL                                              -- ATTRIBUTE11
--        , NULL                                              -- ATTRIBUTE12
--        , NULL                                              -- ATTRIBUTE13
--        , NULL                                              -- ATTRIBUTE14
--        , NULL                                              -- ATTRIBUTE15
--        , xx00_global_pkg.user_id                           -- CREATED_BY
--        , xx00_date_pkg.get_system_datetime_f               -- CREATION_DATE
--        , xx00_global_pkg.user_id                           -- LAST_UPDATED_BY
--        , xx00_date_pkg.get_system_datetime_f               -- LAST_UPDATE_DATE
--        , xx00_global_pkg.login_id                          -- LAST_UPDATE_LOGIN
--        , xx00_global_pkg.conc_request_id                   -- REQUEST_ID
--        , xx00_global_pkg.prog_appl_id                      -- PROGRAM_APPLICATION_ID
--        , xx00_global_pkg.conc_program_id                   -- PROGRAM_ID
--        , xx00_date_pkg.get_system_datetime_f               -- PROGRAM_UPDATE_DATE
--      );
----
--      -- ���טA�ԉ��Z
--      ln_line_count := ln_line_count + 1;
----
--    END LOOP xx03_if_detail_loop;
--    CLOSE xx03_if_detail_cur;
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
--   * Description      : �����˗��̓��̓`�F�b�N(E-2)
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
--    -- �ڋq�`�F�b�N
--    IF ( xx03_if_header_rec.CUSTOMER_NAME IS NULL
--           OR TRIM(xx03_if_header_rec.CUSTOMER_NAME) = '' ) THEN
--      -- �ڋq����̏ꍇ�͌ڋq���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08029'
--        )
--      );
--    END IF;
----
--    -- �ڋq���Ə��`�F�b�N
--    IF ( xx03_if_header_rec.CUSTOMER_OFFICE_ID IS NULL
--           OR TRIM(xx03_if_header_rec.CUSTOMER_OFFICE_ID) = '' ) THEN
--      -- �ڋq���Ə�����̏ꍇ�͌ڋq���Ə����̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08030'
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
---- ver 1.2 Change Start
--    -- �x�����@�`�F�b�N
----    IF ( xx03_if_header_rec.RECEIPT_METHOD_NAME IS NULL
----           OR TRIM(xx03_if_header_rec.RECEIPT_METHOD_NAME) = '' ) THEN
--    IF ( xx03_if_header_rec.RECEIPT_METHOD_ID IS NULL
--           OR TRIM(xx03_if_header_rec.RECEIPT_METHOD_ID) = '' ) THEN
--      -- �x�����@����̏ꍇ�͎x�����@���̓G���[�\��
--      -- �X�e�[�^�X���G���[��
--      gv_result := cv_result_error;
--      -- �G���[�������Z
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
----          'APP-XX03-08015'
--          'APP-XX03-08031'
--        )
--      );
--    END IF;
---- ver 1.2 Change End
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
--    ln_commitment_amount NUMBER; -- �O����z
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
--    -- �{�̋��z���v�Z�o�i�{�̋��z���S���ׂ̖{�̋��z�̍��v�j
--    SELECT SUM(xrsl.ENTERED_ITEM_AMOUNT) as ENTERED_ITEM_AMOUNT
--      INTO ln_total_item_amount
--      FROM XX03_RECEIVABLE_SLIPS_LINE xrsl
--     WHERE xrsl.RECEIVABLE_ID = gn_receivable_id
--    GROUP BY xrsl.RECEIVABLE_ID;
----
--    -- �w�b�_���R�[�h�ɖ{�̍��v���z�Z�b�g
--    UPDATE XX03_RECEIVABLE_SLIPS xrs
--       SET xrs.INV_ITEM_AMOUNT = ln_total_item_amount
--     WHERE xrs.RECEIVABLE_ID   = gn_receivable_id;
----
--    -- ����Ŋz���v�i����Ŋz���S���ׂ̏���Ŋz�̍��v�j
--    SELECT SUM(xrsl.ENTERED_TAX_AMOUNT) as ENTERED_TAX_AMOUNT
--      INTO ln_total_tax_amount
--      FROM XX03_RECEIVABLE_SLIPS_LINE xrsl
--     WHERE xrsl.RECEIVABLE_ID = gn_receivable_id
--    GROUP BY xrsl.RECEIVABLE_ID;
----
--    -- �w�b�_���R�[�h�ɖ{�̍��v���z�Z�b�g
--    UPDATE XX03_RECEIVABLE_SLIPS xrs
--       SET xrs.INV_TAX_AMOUNT = ln_total_tax_amount
--     WHERE xrs.RECEIVABLE_ID  = gn_receivable_id;
----
--    -- �[�����z�v�Z
--    -- �O��[���`�[�ԍ��̎w�肪����ꍇ
--    IF ( xx03_if_header_rec.COMMITMENT_NUMBER IS NOT NULL ) THEN
--      BEGIN
--        -- �O��[���`�[�ԍ��őI�������`�[�ԍ��̏[�����z���擾����B
--        SELECT xcnl.COMMITMENT_AMOUNT
--          INTO ln_commitment_amount
--          FROM XX03_COMMITMENT_NUMBER_LOV_V xcnl
--         WHERE xcnl.TRX_NUMBER = xx03_if_header_rec.COMMITMENT_NUMBER;
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
--      IF ( ln_commitment_amount > (ln_total_item_amount + ln_total_tax_amount)) THEN
--        ln_commitment_amount := ln_total_item_amount + ln_total_tax_amount;
--      END IF;
--    ELSE
--      -- �[���`�[�Ȃ�
--      ln_commitment_amount := 0;
--    END IF;
----
--    -- �x�����z�v�Z�i�x�����z���{�̋��z�{����Ŋz�|�[�����z�j
--    -- �w�b�_���R�[�h�Ɏx�����z�Z�b�g
--    UPDATE XX03_RECEIVABLE_SLIPS xrs
--       SET xrs.INV_AMOUNT = (ln_total_item_amount + ln_total_tax_amount) - ln_commitment_amount,
--           xrs.COMMITMENT_AMOUNT = ln_commitment_amount
--     WHERE xrs.RECEIVABLE_ID = gn_receivable_id;
----
--   -- ���Z�ύ��v���z�v�Z
--   -- �@�\�ʉ݃R�[�h�擾
--   SELECT gsob.currency_code
--     INTO lv_cur_code
--     FROM gl_sets_of_books gsob
--    WHERE gsob.set_of_books_id = xx00_profile_pkg.value(cv_prof_GL_ID);
----
--   -- �ʉ݃R�[�h���@�\�ʉ݂̏ꍇ
--   IF ( xx03_if_header_rec.INVOICE_CURRENCY_CODE = lv_cur_code ) THEN
----
--     -- ���Z�ύ��v���z���x�����z
--     UPDATE XX03_RECEIVABLE_SLIPS xrs
--        SET xrs.INV_ACCOUNTED_AMOUNT = (ln_total_item_amount + ln_total_tax_amount)
--                                         - ln_commitment_amount
--      WHERE xrs.RECEIVABLE_ID = gn_receivable_id;
--   -- �ʉ݃R�[�h���@�\�ʉ݂łȂ��ꍇ
--   ELSE
--     -- ���Z�ύ��v���z���i�x�����z�~���[�g�j���l�̌ܓ������l�m���l�̌ܓ����s���P�ʂ͋@�\�ʉ݈ˑ��n
--     SELECT TO_NUMBER(
--              TO_CHAR(
--                (((ln_total_item_amount + ln_total_tax_amount) - ln_commitment_amount)
--                  * xx03_if_header_rec.CONVERSION_RATE),
--                xx00_currency_pkg.get_format_mask(lv_cur_code, 38)
--              ),
--              xx00_currency_pkg.get_format_mask(lv_cur_code, 38)
--            )
--       INTO ln_accounted_amount
--       FROM dual;
----
--     UPDATE XX03_RECEIVABLE_SLIPS xrs
--        SET xrs.INV_ACCOUNTED_AMOUNT = ln_accounted_amount
--      WHERE xrs.RECEIVABLE_ID = gn_receivable_id;
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
--    ln_interface_id  NUMBER;          -- INTERFACE_ID
--    ln_header_count  NUMBER;          -- INTERFACE_ID����l�w�b�_����
--    ld_terms_date    DATE;            -- �����\���
--    lv_terms_flg     VARCHAR2(1);     -- �x���\����ύX�\�t���O
--    lv_app_upd       VARCHAR2(1);     -- �d�_�Ǘ��t���O
--    ln_error_cnt     NUMBER;          -- �d��`�F�b�N�G���[����
--    lv_error_flg     VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O
--    lv_error_flg1    VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O1
--    lv_error_msg1    VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W1
--    lv_error_flg2    VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O2
--    lv_error_msg2    VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W2
--    lv_error_flg3    VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O3
--    lv_error_msg3    VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W3
--    lv_error_flg4    VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O4
--    lv_error_msg4    VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W4
--    lv_error_flg5    VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O5
--    lv_error_msg5    VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W5
--    lv_error_flg6    VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O6
--    lv_error_msg6    VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W6
--    lv_error_flg7    VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O7
--    lv_error_msg7    VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W7
--    lv_error_flg8    VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O8
--    lv_error_msg8    VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W8
--    lv_error_flg9    VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O9
--    lv_error_msg9    VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W9
--    lv_error_flg10   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O10
--    lv_error_msg10   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W10
--    lv_error_flg11   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O11
--    lv_error_msg11   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W11
--    lv_error_flg12   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O12
--    lv_error_msg12   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W12
--    lv_error_flg13   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O13
--    lv_error_msg13   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W13
--    lv_error_flg14   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O14
--    lv_error_msg14   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W14
--    lv_error_flg15   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O15
--    lv_error_msg15   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W15
--    lv_error_flg16   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O16
--    lv_error_msg16   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W16
--    lv_error_flg17   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O17
--    lv_error_msg17   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W17
--    lv_error_flg18   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O18
--    lv_error_msg18   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W18
--    lv_error_flg19   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O19
--    lv_error_msg19   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W19
--    lv_error_flg20   VARCHAR2(1);     -- �d��`�F�b�N�G���[�t���O20
--    lv_error_msg20   VARCHAR2(5000);  -- �d��`�F�b�N�G���[���b�Z�[�W20
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
--    -- �V�X�e�����J�[�\���I�[�v��
--    OPEN sys_tax_cur;
--      FETCH sys_tax_cur INTO sys_tax_rec;
--    CLOSE sys_tax_cur;
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
--      SELECT COUNT(xrsi.INTERFACE_ID)
--        INTO ln_header_count
--        FROM XX03_RECEIVABLE_SLIPS_IF xrsi
--       WHERE xrsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID
--         AND xrsi.REQUEST_ID   = in_request_id
--         AND xrsi.SOURCE       = iv_source;
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
--        -- ����Ōv�Z���x���E����Œ[�������̐ݒ�𔻒f���ϐ��֊i�[����
--        -- �V�X�e���p�����[�^OVERRIDE�\�Ȃ�ʂ̒l���g�p
--        IF (sys_tax_rec.TAX_ROUNDING_ALLOW_OVERRIDE = cv_yes) THEN
----
--          IF (xx03_if_header_rec.AUTO_TAX_CALC_FLAG IS NULL) THEN
--          -- ���Ə��P�ʂ������͂Ȃ��ʃ��x�����g�p
--            IF (xx03_if_header_rec.AUTO_TAX_CALC_FLAG_C IS NULL) THEN
--            -- �ڋq�P�ʂ������͂Ȃ�V�X�e���p�����[�^���g�p
--              xx03_if_header_rec.AUTO_TAX_CALC_FLAG := sys_tax_rec.TAX_HEADER_LEVEL_FLAG;
--            ELSE
--            -- �ڋq�P�ʂ����͂���Ă���Όڋq�P�ʂ��g�p
--              xx03_if_header_rec.AUTO_TAX_CALC_FLAG := xx03_if_header_rec.AUTO_TAX_CALC_FLAG_C;
--            END IF;
--          END IF;
----
--          IF (xx03_if_header_rec.TAX_ROUNDING_RULE IS NULL) THEN
--          -- ���Ə��P�ʂ������͂Ȃ��ʃ��x�����g�p
--            IF (xx03_if_header_rec.TAX_ROUNDING_RULE_C IS NULL) THEN
--            -- �ڋq�P�ʂ������͂Ȃ�V�X�e���p�����[�^���g�p
--              xx03_if_header_rec.TAX_ROUNDING_RULE := sys_tax_rec.TAX_ROUNDING_RULE;
--            ELSE
--            -- �ڋq�P�ʂ����͂���Ă���Όڋq�P�ʂ��g�p
--              xx03_if_header_rec.TAX_ROUNDING_RULE := xx03_if_header_rec.TAX_ROUNDING_RULE_C;
--            END IF;
--          END IF;
----
--        ELSE
--        -- �V�X�e���p�����[�^OVERRIDE�s�Ȃ�V�X�e���̒l���g�p
--          xx03_if_header_rec.AUTO_TAX_CALC_FLAG  := sys_tax_rec.TAX_HEADER_LEVEL_FLAG;
--          xx03_if_header_rec.TAX_ROUNDING_RULE   := sys_tax_rec.TAX_ROUNDING_RULE;
--        END IF;
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
--          -- �����\����擾(E-4)
--          -- ===============================
--        xx03_deptinput_ar_check_pkg.get_terms_date(
--          xx03_if_header_rec.TERMS_ID,                    -- �x������ID
--          xx03_if_header_rec.INVOICE_DATE,                -- ���������t
--          ld_terms_date,                                  -- �����\���
--          lv_errbuf,
--          lv_retcode,
--          lv_errmsg
--        );
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
--            -- �`�[ID�擾
--            SELECT XX03_RECEIVABLE_SLIPS_S.nextval
--              INTO gn_receivable_id
--              FROM dual;
----
--            -- �C���^�[�t�F�[�X�e�[�u��������ID�X�V
--            UPDATE XX03_RECEIVABLE_SLIPS_IF xrsi
--               SET RECEIVABLE_ID     = gn_receivable_id
--             WHERE xrsi.REQUEST_ID   = in_request_id
--               AND xrsi.SOURCE       = iv_source
--               AND xrsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID;
----
--            -- �w�b�_�f�[�^�ۑ�
--            INSERT INTO XX03_RECEIVABLE_SLIPS(
--                RECEIVABLE_ID                  -- �`�[ID
--              , WF_STATUS                      -- �X�e�[�^�X
--              , SLIP_TYPE                      -- �`�[���
--              , RECEIVABLE_NUM                 -- �`�[�ԍ�
--              , ENTRY_DATE                     -- �N�[��
--              , REQUEST_KEY                    -- �\���L�[
--              , REQUESTOR_PERSON_ID            -- �\����
--              , REQUESTOR_PERSON_NAME          -- �\���Җ�
--              , APPROVER_PERSON_ID             -- ���F��
--              , APPROVER_PERSON_NAME           -- ���F�Җ�
--              , REQUEST_DATE                   -- �\����
--              , APPROVAL_DATE                  -- ���F��
--              , REJECTION_DATE                 -- �۔F��
--              , ACCOUNT_APPROVER_PERSON_ID     -- �o�����F��
--              , ACCOUNT_APPROVAL_DATE          -- �o�����F��
--              , AR_FORWARD_DATE                -- AR�]����
--              , RECOGNITION_CLASS              -- ���F��
--              , APPROVER_COMMENTS              -- ���F�R�����g
--              , REQUEST_ENABLE_FLAG            -- �\���\�t���O
--              , ACCOUNT_REVISION_FLAG          -- N_FLAG IS '�o���C���t���O
--              , INVOICE_DATE                   -- ���������t
--              , TRANS_TYPE_ID                  -- ����^�C�vID
--              , TRANS_TYPE_NAME                -- ����^�C�v��
--              , CUSTOMER_ID                    -- �ڋqID
--              , CUSTOMER_NAME                  -- �ڋq��
--              , CUSTOMER_OFFICE_ID             -- �ڋq���Ə�ID
--              , CUSTOMER_OFFICE_NAME           -- �ڋq���Ə���
--              , INV_AMOUNT                     -- �������v���z
--              , INV_ACCOUNTED_AMOUNT           -- ���Z�ύ��v���z
--              , INV_ITEM_AMOUNT                -- �{�̍��v���z
--              , INV_TAX_AMOUNT                 -- ����ō��v���z
--              , INV_PREPAY_AMOUNT              -- �[�����z
--              , INVOICE_CURRENCY_CODE          -- �ʉ�
--              , EXCHANGE_RATE                  -- ���[�g
--              , EXCHANGE_RATE_TYPE             -- ���[�g�^�C�v
--              , EXCHANGE_RATE_TYPE_NAME        -- ���[�g�^�C�v��
--              , RECEIPT_METHOD_ID              -- �x�����@ID
--              , RECEIPT_METHOD_NAME            -- �x�����@��
--              , TERMS_ID                       -- �x������ID
--              , TERMS_NAME                     -- �x��������
--              , DESCRIPTION                    -- ���l
--              , CONTEXT                        -- �R���e�L�X�g
--              , ENTRY_DEPARTMENT               -- �N�[����
--              , ENTRY_PERSON_ID                -- �`�[���͎�
--              , ORIG_INVOICE_NUM               -- �C�����`�[�ԍ�
--              , ACCOUNT_APPROVAL_FLAG          -- �d�_�Ǘ��t���O
--              , GL_DATE                        -- �v���
--              , AUTO_TAX_CALC_FLAG             -- ����Ōv�Z���x��
--              , AP_TAX_ROUNDING_RULE           -- ����Œ[������
--              , ORG_ID                         -- �I���OID
--              , SET_OF_BOOKS_ID                -- ��v����ID
--              , COMMITMENT_NUMBER              -- �O����[���ԍ�
--              , COMMITMENT_AMOUNT              -- �O����c�����z
--              , PAYMENT_SCHEDULED_DATE         -- �����\���
--              , ONETIME_CUSTOMER_NAME          -- �ڋq����
--              , ONETIME_CUSTOMER_KANA_NAME     -- �J�i��
--              , ONETIME_CUSTOMER_ADDRESS_1     -- �Z���P
--              , ONETIME_CUSTOMER_ADDRESS_2     -- �Z���Q
--              , ONETIME_CUSTOMER_ADDRESS_3     -- �Z���R
--              , COMMITMENT_NAME                -- �E�v
--              , COMMITMENT_ORIGINAL_AMOUNT     -- ���z
--              , COMMITMENT_DATE_FROM           -- �L�����i���j
--              , COMMITMENT_DATE_TO             -- �L�����i���j
--              , ATTRIBUTE_CATEGORY
--              , ATTRIBUTE1
--              , ATTRIBUTE2
--              , ATTRIBUTE3
--              , ATTRIBUTE4
--              , ATTRIBUTE5
--              , ATTRIBUTE6
--              , ATTRIBUTE7
--              , ATTRIBUTE8
--              , ATTRIBUTE9
--              , ATTRIBUTE10
--              , ATTRIBUTE11
--              , ATTRIBUTE12
--              , ATTRIBUTE13
--              , ATTRIBUTE14
--              , ATTRIBUTE15
--              , CREATED_BY
--              , CREATION_DATE
--              , LAST_UPDATED_BY
--              , LAST_UPDATE_DATE
--              , LAST_UPDATE_LOGIN
--              , REQUEST_ID
--              , PROGRAM_APPLICATION_ID
--              , PROGRAM_ID
--              , PROGRAM_UPDATE_DATE
--              , DELETE_FLAG
--              , FIRST_CUSTOMER_FLAG                         -- �ꌩ�ڋq�敪
--            )
--            VALUES(
--                gn_receivable_id                            -- �`�[ID
--              , xx03_if_header_rec.WF_STATUS                -- �X�e�[�^�X
--              , xx03_if_header_rec.SLIP_TYPE                -- �`�[���
--              , gn_receivable_id                            -- �`�[�ԍ�
--              , xx03_if_header_rec.ENTRY_DATE               -- �N�[��
--              , NULL                                        -- �\���L�[
--              , xx03_if_header_rec.REQUESTOR_PERSON_ID      -- �\����
--              , xx03_if_header_rec.REQUESTOR_PERSON_NAME    -- �\���Җ�
--              , xx03_if_header_rec.APPROVER_PERSON_ID       -- ���F��
--              , xx03_if_header_rec.APPROVER_PERSON_NAME     -- ���F�Җ�
--              , NULL                                        -- �\����
--              , NULL                                        -- ���F��
--              , NULL                                        -- �۔F��
--              , NULL                                        -- �o�����F��
--              , NULL                                        -- �o�����F��
--              , NULL                                        -- AR�]����
--              , 0                                           -- ���F��
--              , NULL                                        -- ���F�R�����g
--              , 'N'                                         -- �\���\�t���O
--              , 'N'                                         -- �o���C���t���O
--              , xx03_if_header_rec.INVOICE_DATE             -- ���������t
--              , xx03_if_header_rec.TRANS_TYPE_ID            -- ����^�C�vID
--              , xx03_if_header_rec.TRANS_TYPE_NAME          -- ����^�C�v��
--              , xx03_if_header_rec.CUSTOMER_ID              -- �ڋqID
--              , xx03_if_header_rec.CUSTOMER_NAME            -- �ڋq��
--              , xx03_if_header_rec.CUSTOMER_OFFICE_ID       -- �ڋq���Ə�ID
--              , xx03_if_header_rec.CUSTOMER_OFFICE_NAME     -- �ڋq���Ə���
--              , 0                                           -- �������v���z�iE-3�ōX�V�j
--              , 0                                           -- ���Z�ύ��v���z
--              , 0                                           -- �{�̍��v���z�iE-3�ōX�V�j
--              , 0                                           -- ����ō��v���z�iE-3�ōX�V�j
--              , 0                                           -- �[�����z
--              , xx03_if_header_rec.INVOICE_CURRENCY_CODE    -- �ʉ�
--              , xx03_if_header_rec.CONVERSION_RATE          -- ���[�g
--              , xx03_if_header_rec.EXCHANGE_RATE_TYPE       -- ���[�g�^�C�v
--              , xx03_if_header_rec.EXCHANGE_RATE_TYPE_NAME  -- ���[�g�^�C�v��
--              , xx03_if_header_rec.RECEIPT_METHOD_ID        -- �x�����@ID
--              , xx03_if_header_rec.RECEIPT_METHOD_NAME      -- �x�����@��
--              , xx03_if_header_rec.TERMS_ID                 -- �x������ID
--              , xx03_if_header_rec.TERMS_NAME               -- �x��������
--              , xx03_if_header_rec.DESCRIPTION              -- ���l
--              , NULL                                        -- �R���e�L�X�g
--              , xx03_if_header_rec.ENTRY_DEPARTMENT         -- �N�[����
--              , xx03_if_header_rec.ENTRY_PERSON_ID          -- �`�[���͎�
--              , NULL                                        -- �C�����`�[�ԍ�
--              , 'N'                                         -- �d�_�Ǘ��t���O
--              , xx03_if_header_rec.GL_DATE                  -- �v���
--              , xx03_if_header_rec.AUTO_TAX_CALC_FLAG       -- ����Ōv�Z���x��
--              , xx03_if_header_rec.TAX_ROUNDING_RULE        -- ����Œ[������
--              , xx03_if_header_rec.ORG_ID                   -- �I���OID
--              , xx00_profile_pkg.value(cv_prof_GL_ID)       -- ��v����ID
--              , xx03_if_header_rec.COMMITMENT_NUMBER        -- �O����[���ԍ�
--              , NULL                                        -- �O����c�����z
--              , ld_terms_date                               -- �����\���
--              , xx03_if_header_rec.ONETIME_CUSTOMER_NAME       -- �ڋq����
--              , xx03_if_header_rec.ONETIME_CUSTOMER_KANA_NAME  -- �J�i��
--              , xx03_if_header_rec.ONETIME_CUSTOMER_ADDRESS_1  -- �Z���P
--              , xx03_if_header_rec.ONETIME_CUSTOMER_ADDRESS_2  -- �Z���Q
--              , xx03_if_header_rec.ONETIME_CUSTOMER_ADDRESS_3  -- �Z���R
--              , NULL                                        -- �E�v
--              , 0                                           -- ���z
--              , NULL                                        -- �L�����i���j
--              , NULL                                        -- �L�����i���j
--              , NULL                                        -- ATTRIBUTE_CATEGORY
--              , NULL                                        -- ATTRIBUTE1
--              , NULL                                        -- ATTRIBUTE2
--              , NULL                                        -- ATTRIBUTE3
--              , NULL                                        -- ATTRIBUTE4
--              , NULL                                        -- ATTRIBUTE5
--              , NULL                                        -- ATTRIBUTE6
--              , NULL                                        -- ATTRIBUTE7
--              , NULL                                        -- ATTRIBUTE8
--              , NULL                                        -- ATTRIBUTE9
--              , NULL                                        -- ATTRIBUTE10
--              , NULL                                        -- ATTRIBUTE11
--              , NULL                                        -- ATTRIBUTE12
--              , NULL                                        -- ATTRIBUTE13
--              , NULL                                        -- ATTRIBUTE14
--              , NULL                                        -- ATTRIBUTE15
--              , xx00_global_pkg.user_id                     -- CREATED_BY
--              , xx00_date_pkg.get_system_datetime_f         -- CREATION_DATE
--              , xx00_global_pkg.user_id                     -- LAST_UPDATED_BY
--              , xx00_date_pkg.get_system_datetime_f         -- LAST_UPDATE_DATE
--              , xx00_global_pkg.login_id                    -- LAST_UPDATE_LOGIN
--              , xx00_global_pkg.conc_request_id             -- REQUEST_ID
--              , xx00_global_pkg.prog_appl_id                -- PROGRAM_APPLICATION_ID
--              , xx00_global_pkg.conc_program_id             -- PROGRAM_ID
--              , xx00_date_pkg.get_system_datetime_f         -- PROGRAM_UPDATE_DATE
--              , 'N'                                         -- �폜�t���O�FY=�폜,N=��폜
--              , DECODE(xx03_if_header_rec.ONETIME_CUSTOMER_NAME, NULL, 'N', 'Y')  -- �ꌩ�ڋq�敪
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
--            xx03_deptinput_ar_check_pkg.set_account_approval_flag(
--              gn_receivable_id,
--              lv_app_upd,
--              lv_errbuf,
--              lv_retcode,
--              lv_errmsg
--            );
--            IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--              -- ���ʂ�����Ȃ�A�w�b�_���R�[�h�̏d�_�Ǘ��t���O���X�V
--              UPDATE XX03_RECEIVABLE_SLIPS xrs
--                 SET xrs.ACCOUNT_APPROVAL_FLAG = lv_app_upd    -- �d�_�Ǘ��t���O
--               WHERE xrs.RECEIVABLE_ID = gn_receivable_id;
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
--            xx03_deptinput_ar_check_pkg.check_deptinput_ar (
--              gn_receivable_id,
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
----
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
    SELECT XX03_RECEIVABLE_SLIPS_S.nextval
    INTO   gn_receivable_id
    FROM   dual;
--
    -- �C���^�[�t�F�[�X�e�[�u��������ID�X�V
    UPDATE XX03_RECEIVABLE_SLIPS_IF xrsi
    SET    RECEIVABLE_ID     = gn_receivable_id
    WHERE  xrsi.REQUEST_ID   = in_request_id
      AND  xrsi.SOURCE       = iv_source
      AND  xrsi.INTERFACE_ID = xx03_if_head_line_rec.HEAD_INTERFACE_ID;
--
    -- ����Ōv�Z���x���E����Œ[�������̐ݒ�𔻒f���ϐ��֊i�[����
    -- �V�X�e���p�����[�^OVERRIDE�\�Ȃ�ʂ̒l���g�p
    IF (sys_tax_rec.TAX_ROUNDING_ALLOW_OVERRIDE = cv_yes) THEN
--
      IF (xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG IS NULL) THEN
      -- ���Ə��P�ʂ������͂Ȃ��ʃ��x�����g�p
        IF (xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG_C IS NULL) THEN
        -- �ڋq�P�ʂ������͂Ȃ�V�X�e���p�����[�^���g�p
          xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG := sys_tax_rec.TAX_HEADER_LEVEL_FLAG;
        ELSE
        -- �ڋq�P�ʂ����͂���Ă���Όڋq�P�ʂ��g�p
          xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG := xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG_C;
        END IF;
      END IF;
--
      IF (xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE IS NULL) THEN
      -- ���Ə��P�ʂ������͂Ȃ��ʃ��x�����g�p
        IF (xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE_C IS NULL) THEN
        -- �ڋq�P�ʂ������͂Ȃ�V�X�e���p�����[�^���g�p
          xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE := sys_tax_rec.TAX_ROUNDING_RULE;
        ELSE
        -- �ڋq�P�ʂ����͂���Ă���Όڋq�P�ʂ��g�p
          xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE := xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE_C;
        END IF;
      END IF;
--
    ELSE
    -- �V�X�e���p�����[�^OVERRIDE�s�Ȃ�V�X�e���̒l���g�p
      xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG  := sys_tax_rec.TAX_HEADER_LEVEL_FLAG;
      xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE   := sys_tax_rec.TAX_ROUNDING_RULE;
    END IF;
--
    -- �w�b�_�f�[�^�ۑ�
    INSERT INTO XX03_RECEIVABLE_SLIPS(
        RECEIVABLE_ID                  -- �`�[ID
      , WF_STATUS                      -- �X�e�[�^�X
      , SLIP_TYPE                      -- �`�[���
      , RECEIVABLE_NUM                 -- �`�[�ԍ�
      , ENTRY_DATE                     -- �N�[��
      , REQUEST_KEY                    -- �\���L�[
      , REQUESTOR_PERSON_ID            -- �\����
      , REQUESTOR_PERSON_NAME          -- �\���Җ�
      , APPROVER_PERSON_ID             -- ���F��
      , APPROVER_PERSON_NAME           -- ���F�Җ�
      , REQUEST_DATE                   -- �\����
      , APPROVAL_DATE                  -- ���F��
      , REJECTION_DATE                 -- �۔F��
      , ACCOUNT_APPROVER_PERSON_ID     -- �o�����F��
      , ACCOUNT_APPROVAL_DATE          -- �o�����F��
      , AR_FORWARD_DATE                -- AR�]����
      , RECOGNITION_CLASS              -- ���F��
      , APPROVER_COMMENTS              -- ���F�R�����g
      , REQUEST_ENABLE_FLAG            -- �\���\�t���O
      , ACCOUNT_REVISION_FLAG          -- N_FLAG IS '�o���C���t���O
      , INVOICE_DATE                   -- ���������t
      , TRANS_TYPE_ID                  -- ����^�C�vID
      , TRANS_TYPE_NAME                -- ����^�C�v��
      , CUSTOMER_ID                    -- �ڋqID
      , CUSTOMER_NAME                  -- �ڋq��
      , CUSTOMER_OFFICE_ID             -- �ڋq���Ə�ID
      , CUSTOMER_OFFICE_NAME           -- �ڋq���Ə���
      , INV_AMOUNT                     -- �������v���z
      , INV_ACCOUNTED_AMOUNT           -- ���Z�ύ��v���z
      , INV_ITEM_AMOUNT                -- �{�̍��v���z
      , INV_TAX_AMOUNT                 -- ����ō��v���z
      , INV_PREPAY_AMOUNT              -- �[�����z
      , INVOICE_CURRENCY_CODE          -- �ʉ�
      , EXCHANGE_RATE                  -- ���[�g
      , EXCHANGE_RATE_TYPE             -- ���[�g�^�C�v
      , EXCHANGE_RATE_TYPE_NAME        -- ���[�g�^�C�v��
      , RECEIPT_METHOD_ID              -- �x�����@ID
      , RECEIPT_METHOD_NAME            -- �x�����@��
      , TERMS_ID                       -- �x������ID
      , TERMS_NAME                     -- �x��������
      , DESCRIPTION                    -- ���l
      , CONTEXT                        -- �R���e�L�X�g
      , ENTRY_DEPARTMENT               -- �N�[����
      , ENTRY_PERSON_ID                -- �`�[���͎�
      , ORIG_INVOICE_NUM               -- �C�����`�[�ԍ�
      , ACCOUNT_APPROVAL_FLAG          -- �d�_�Ǘ��t���O
      , GL_DATE                        -- �v���
      , AUTO_TAX_CALC_FLAG             -- ����Ōv�Z���x��
      , AP_TAX_ROUNDING_RULE           -- ����Œ[������
      , ORG_ID                         -- �I���OID
      , SET_OF_BOOKS_ID                -- ��v����ID
      , COMMITMENT_NUMBER              -- �O����[���ԍ�
      , COMMITMENT_AMOUNT              -- �O����c�����z
      , PAYMENT_SCHEDULED_DATE         -- �����\���
      , ONETIME_CUSTOMER_NAME          -- �ڋq����
      , ONETIME_CUSTOMER_KANA_NAME     -- �J�i��
      , ONETIME_CUSTOMER_ADDRESS_1     -- �Z���P
      , ONETIME_CUSTOMER_ADDRESS_2     -- �Z���Q
      , ONETIME_CUSTOMER_ADDRESS_3     -- �Z���R
      , COMMITMENT_NAME                -- �E�v
      , COMMITMENT_ORIGINAL_AMOUNT     -- ���z
      , COMMITMENT_DATE_FROM           -- �L�����i���j
      , COMMITMENT_DATE_TO             -- �L�����i���j
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE1
      , ATTRIBUTE2
      , ATTRIBUTE3
      , ATTRIBUTE4
      , ATTRIBUTE5
      , ATTRIBUTE6
      , ATTRIBUTE7
      , ATTRIBUTE8
      , ATTRIBUTE9
      , ATTRIBUTE10
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , CREATED_BY
      , CREATION_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , DELETE_FLAG
      , FIRST_CUSTOMER_FLAG            -- �ꌩ�ڋq�敪
      -- ver 11.5.10.2.13 Add Start
      , PAYMENT_ELE_DATA_YES                                -- �x���ē����d�q�f�[�^��̂���
      , PAYMENT_ELE_DATA_NO                                 -- �x���ē����d�q�f�[�^��̂Ȃ�
      -- ver 11.5.10.2.13 Add End
-- Ver11.5.10.2.14 ADD START
      , DRAFTING_COMPANY                                    -- �`�[�쐬���
-- Ver11.5.10.2.14 ADD END
    )
    VALUES(
        gn_receivable_id                                    -- �`�[ID
      , xx03_if_head_line_rec.HEAD_WF_STATUS                -- �X�e�[�^�X
      , xx03_if_head_line_rec.HEAD_SLIP_TYPE                -- �`�[���
      , gn_receivable_id                                    -- �`�[�ԍ�
      , xx03_if_head_line_rec.HEAD_ENTRY_DATE               -- �N�[��
      , NULL                                                -- �\���L�[
      , xx03_if_head_line_rec.HEAD_REQUESTOR_PERSON_ID      -- �\����
      , xx03_if_head_line_rec.HEAD_REQUESTOR_PERSON_NAME    -- �\���Җ�
      , xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID       -- ���F��
      , xx03_if_head_line_rec.HEAD_APPROVER_PERSON_NAME     -- ���F�Җ�
      , NULL                                                -- �\����
      , NULL                                                -- ���F��
      , NULL                                                -- �۔F��
      , NULL                                                -- �o�����F��
      , NULL                                                -- �o�����F��
      , NULL                                                -- AR�]����
      , 0                                                   -- ���F��
      , NULL                                                -- ���F�R�����g
      , 'N'                                                 -- �\���\�t���O
      , 'N'                                                 -- �o���C���t���O
      , xx03_if_head_line_rec.HEAD_INVOICE_DATE             -- ���������t
      , xx03_if_head_line_rec.HEAD_TRANS_TYPE_ID            -- ����^�C�vID
      , xx03_if_head_line_rec.HEAD_TRANS_TYPE_NAME          -- ����^�C�v��
      , xx03_if_head_line_rec.HEAD_CUSTOMER_ID              -- �ڋqID
      , xx03_if_head_line_rec.HEAD_CUSTOMER_NAME            -- �ڋq��
      , xx03_if_head_line_rec.HEAD_CUSTOMER_OFFICE_ID       -- �ڋq���Ə�ID
      , xx03_if_head_line_rec.HEAD_CUSTOMER_OFFICE_NAME     -- �ڋq���Ə���
      , 0                                                   -- �������v���z�iE-3�ōX�V�j
      , 0                                                   -- ���Z�ύ��v���z
      , 0                                                   -- �{�̍��v���z�iE-3�ōX�V�j
      , 0                                                   -- ����ō��v���z�iE-3�ōX�V�j
      , 0                                                   -- �[�����z
      , xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE    -- �ʉ�
      , xx03_if_head_line_rec.HEAD_CONVERSION_RATE          -- ���[�g
      , xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE       -- ���[�g�^�C�v
      , xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE_NAME  -- ���[�g�^�C�v��
      , xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_ID        -- �x�����@ID
      , xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_NAME      -- �x�����@��
      , xx03_if_head_line_rec.HEAD_TERMS_ID                 -- �x������ID
      , xx03_if_head_line_rec.HEAD_TERMS_NAME               -- �x��������
      , xx03_if_head_line_rec.HEAD_DESCRIPTION              -- ���l
      , NULL                                                -- �R���e�L�X�g
      , xx03_if_head_line_rec.HEAD_ENTRY_DEPARTMENT         -- �N�[����
      , xx03_if_head_line_rec.HEAD_ENTRY_PERSON_ID          -- �`�[���͎�
      , NULL                                                -- �C�����`�[�ԍ�
      , 'N'                                                 -- �d�_�Ǘ��t���O
      , xx03_if_head_line_rec.HEAD_GL_DATE                  -- �v���
      , xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG       -- ����Ōv�Z���x��
      , xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE        -- ����Œ[������
      , xx03_if_head_line_rec.HEAD_ORG_ID                   -- �I���OID
      , xx00_profile_pkg.value(cv_prof_GL_ID)               -- ��v����ID
      , xx03_if_head_line_rec.HEAD_COMMITMENT_NUMBER        -- �O����[���ԍ�
      , NULL                                                -- �O����c�����z
      , id_terms_date                                       -- �����\���
      , xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_NAME        -- �ڋq����
      , xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_KANA_NAME   -- �J�i��
      , xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_ADDRESS_1   -- �Z���P
      , xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_ADDRESS_2   -- �Z���Q
      , xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_ADDRESS_3   -- �Z���R
      , NULL                                                -- �E�v
      , 0                                                   -- ���z
      , NULL                                                -- �L�����i���j
      , NULL                                                -- �L�����i���j
      , NULL                                                -- ATTRIBUTE_CATEGORY
      , NULL                                                -- ATTRIBUTE1
      , NULL                                                -- ATTRIBUTE2
      , NULL                                                -- ATTRIBUTE3
      , NULL                                                -- ATTRIBUTE4
      , NULL                                                -- ATTRIBUTE5
      , NULL                                                -- ATTRIBUTE6
      , NULL                                                -- ATTRIBUTE7
      , NULL                                                -- ATTRIBUTE8
      , NULL                                                -- ATTRIBUTE9
      , NULL                                                -- ATTRIBUTE10
      , NULL                                                -- ATTRIBUTE11
      , NULL                                                -- ATTRIBUTE12
      , NULL                                                -- ATTRIBUTE13
      , NULL                                                -- ATTRIBUTE14
      , NULL                                                -- ATTRIBUTE15
      , xx00_global_pkg.user_id                             -- CREATED_BY
      , xx00_date_pkg.get_system_datetime_f                 -- CREATION_DATE
      , xx00_global_pkg.user_id                             -- LAST_UPDATED_BY
      , xx00_date_pkg.get_system_datetime_f                 -- LAST_UPDATE_DATE
      , xx00_global_pkg.login_id                            -- LAST_UPDATE_LOGIN
      , xx00_global_pkg.conc_request_id                     -- REQUEST_ID
      , xx00_global_pkg.prog_appl_id                        -- PROGRAM_APPLICATION_ID
      , xx00_global_pkg.conc_program_id                     -- PROGRAM_ID
      , xx00_date_pkg.get_system_datetime_f                 -- PROGRAM_UPDATE_DATE
      , 'N'                                                 -- �폜�t���O�FY=�폜,N=��폜
      , DECODE(xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_NAME, NULL, 'N', 'Y')  -- �ꌩ�ڋq�敪
      -- ver 11.5.10.2.13 Add Start
      , xx03_if_head_line_rec.HEAD_PAYMENT_ELE_DATA_YES     -- �x���ē����d�q�f�[�^��̂���
      , xx03_if_head_line_rec.HEAD_PAYMENT_ELE_DATA_NO      -- �x���ē����d�q�f�[�^��̂Ȃ�
      -- ver 11.5.10.2.13 Add End
-- Ver11.5.10.2.14 ADD START
      , xx03_if_head_line_rec.DRAFTING_COMPANY              -- �`�[�쐬���
-- Ver11.5.10.2.14 ADD END
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
    on_ent_amount OUT NUMBER,          -- ���z
    ov_errbuf     OUT VARCHAR2,     --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--    ln_ent_amount     NUMBER;          -- ���z
    lv_slip_type_name VARCHAR2(4000);  -- �E�v����
--
    -- ver 11.5.10.2.10G Add Start
    ln_precision      NUMBER;          -- �ʉݐ��x
    -- ver 11.5.10.2.10G Add End
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
    SELECT XX03_RECEIVABLE_SLIPS_LINE_S.nextval
    INTO   ln_line_id
    FROM   dual;
--
    -- ���z�Z�o
    -- ���͋��z���P��������
    ln_amount := xx03_if_head_line_rec.LINE_SLIP_LINE_UNIT_PRICE * xx03_if_head_line_rec.LINE_SLIP_LINE_QUANTITY;
--
    -- ver 11.5.10.2.10G Add Start
    -- �ʉݐ��x�擾
    SELECT NVL(fc.precision ,0) PRECISION
      INTO ln_precision
      FROM fnd_currencies fc
     WHERE fc.currency_code = xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE
    ;
--
    SELECT ROUND(ln_amount ,ln_precision)
      INTO ln_amount
      FROM Dual
    ;
    -- ver 11.5.10.2.10G Add Start
--
    -- '����'��'Y'�̎�
    IF ( xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_FLAG = cv_yes ) THEN
      -- �{�̋��z�����͋��z�|����Ŋz
      on_ent_amount  :=  ln_amount - xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT;
    -- '����'��'N'�̎�
    ELSIF  ( xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_FLAG = cv_no ) THEN
      -- �{�̋��z�����͋��z
      on_ent_amount  :=  ln_amount;
    -- ����ȊO�̎�
    ELSE
      -- ���œ��͒l�G���[
      on_ent_amount := 0;
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
    INSERT INTO XX03_RECEIVABLE_SLIPS_LINE(
        RECEIVABLE_LINE_ID             -- ����ID
      , RECEIVABLE_ID                  -- �`�[ID
      , LINE_NUMBER                    -- No
      , SLIP_LINE_TYPE                 -- �������eID
      , SLIP_LINE_TYPE_NAME            -- �������e
      , SLIP_LINE_UOM                  -- �P��
      , SLIP_LINE_UOM_NAME             -- �P�ʖ�
      , SLIP_LINE_UNIT_PRICE           -- �P��
      , SLIP_LINE_QUANTITY             -- ����
      , SLIP_LINE_ENTERED_AMOUNT       -- ���͋��z
      , TAX_CODE                       -- �ŋ敪CODE
      , TAX_NAME                       -- �ŋ敪
      , TAX_ID                         -- �ŋ敪ID
      , AMOUNT_INCLUDES_TAX_FLAG       -- ����
      , ENTERED_ITEM_AMOUNT            -- �{�̋��z
      , ENTERED_TAX_AMOUNT             -- ����Ŋz
      , ACCOUNTED_AMOUNT               -- ���Z�ϋ��z
      , SLIP_LINE_RECIEPT_NO           -- �[�i���ԍ�
      , SLIP_DESCRIPTION               -- ���l�i���ׁj
      , SEGMENT1                       -- ���
      , SEGMENT2                       -- ����
      , SEGMENT3                       -- ����Ȗ�
      , SEGMENT4                       -- �⏕�Ȗ�
      , SEGMENT5                       -- �����
      , SEGMENT6                       -- ���Ƌ敪
      , SEGMENT7                       -- �v���W�F�N�g
      , SEGMENT8                       -- �\���P
      , SEGMENT9
      , SEGMENT10
      , SEGMENT11
      , SEGMENT12
      , SEGMENT13
      , SEGMENT14
      , SEGMENT15
      , SEGMENT16
      , SEGMENT17
      , SEGMENT18
      , SEGMENT19
      , SEGMENT20
      , SEGMENT1_NAME
      , SEGMENT2_NAME
      , SEGMENT3_NAME
      , SEGMENT4_NAME
      , SEGMENT5_NAME
      , SEGMENT6_NAME
      , SEGMENT7_NAME
      , SEGMENT8_NAME
      , INCR_DECR_REASON_CODE          -- �������R
      , INCR_DECR_REASON_NAME          -- �������R��
      , RECON_REFERENCE                -- �����Q��
      , JOURNAL_DESCRIPTION            -- ���l�i�d��j
      , ORG_ID                         -- �I���OID
      , ATTRIBUTE_CATEGORY
      , ATTRIBUTE1
      , ATTRIBUTE2
      , ATTRIBUTE3
      , ATTRIBUTE4
      , ATTRIBUTE5
      , ATTRIBUTE6
      , ATTRIBUTE7
      , ATTRIBUTE8
      , ATTRIBUTE9
      , ATTRIBUTE10
      , ATTRIBUTE11
      , ATTRIBUTE12
      , ATTRIBUTE13
      , ATTRIBUTE14
      , ATTRIBUTE15
      , CREATED_BY
      , CREATION_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
    )
    VALUES(
        ln_line_id                                        -- ����ID
      , gn_receivable_id                                  -- �`�[ID
      , in_line_count                                     -- No
      , xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE         -- �������eID
      , xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE_NAME    -- �������e
      , xx03_if_head_line_rec.LINE_SLIP_LINE_UOM          -- �P��
      , xx03_if_head_line_rec.LINE_SLIP_LINE_UOM_NAME     -- �P��
      , xx03_if_head_line_rec.LINE_SLIP_LINE_UNIT_PRICE   -- �P��
      , xx03_if_head_line_rec.LINE_SLIP_LINE_QUANTITY     -- ����
      , ln_amount                                         -- ���͋��z
      , xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_CODE     -- �ŋ敪ID
      , xx03_if_head_line_rec.LINE_TAX_NAME               -- �ŋ敪
      , xx03_if_head_line_rec.LINE_VAT_TAX_ID             -- �ŋ敪ID
      , xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_FLAG     -- ����
      , on_ent_amount                                     -- �{�̋��z
      , xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT     -- ����Ŋz
      , 0                                                 -- ���Z�ϋ��z
      , xx03_if_head_line_rec.LINE_SLIP_LINE_RECIEPT_NO   -- �[�i���ԍ�
      , xx03_if_head_line_rec.LINE_SLIP_DESCRIPTION       -- ���l�i���ׁj
      , xx03_if_head_line_rec.LINE_SEGMENT1               -- ���
      , xx03_if_head_line_rec.LINE_SEGMENT2               -- ����
      , xx03_if_head_line_rec.LINE_SEGMENT3               -- ����Ȗ�
      , xx03_if_head_line_rec.LINE_SEGMENT4               -- �⏕�Ȗ�
      , xx03_if_head_line_rec.LINE_SEGMENT5               -- �����
      , xx03_if_head_line_rec.LINE_SEGMENT6               -- ���Ƌ敪
      , xx03_if_head_line_rec.LINE_SEGMENT7               -- �v���W�F�N�g
      , xx03_if_head_line_rec.LINE_SEGMENT8               -- �\���P
      , NULL                                              -- SEGMENT9
      , NULL                                              -- SEGMENT10
      , NULL                                              -- SEGMENT11
      , NULL                                              -- SEGMENT12
      , NULL                                              -- SEGMENT13
      , NULL                                              -- SEGMENT14
      , NULL                                              -- SEGMENT15
      , NULL                                              -- SEGMENT16
      , NULL                                              -- SEGMENT17
      , NULL                                              -- SEGMENT18
      , NULL                                              -- SEGMENT19
      , NULL                                              -- SEGMENT20
      , xx03_if_head_line_rec.LINE_SEGMENT1_NAME          -- ��Ж�
      , xx03_if_head_line_rec.LINE_SEGMENT2_NAME          -- ���喼
      , xx03_if_head_line_rec.LINE_SEGMENT3_NAME          -- ����Ȗږ�
      , xx03_if_head_line_rec.LINE_SEGMENT4_NAME          -- �⏕�Ȗږ�
      , xx03_if_head_line_rec.LINE_SEGMENT5_NAME          -- ����於
      , xx03_if_head_line_rec.LINE_SEGMENT6_NAME          -- ���Ƌ敪��
      , xx03_if_head_line_rec.LINE_SEGMENT7_NAME          -- �v���W�F�N�g��
      , xx03_if_head_line_rec.LINE_SEGMENT8_NAME          -- �\���P
      , xx03_if_head_line_rec.LINE_INCR_DECR_REASON_CODE  -- �������R
      , xx03_if_head_line_rec.LINE_INCR_DECR_REASON_NAME  -- �������R��
      , xx03_if_head_line_rec.LINE_RECON_REFERENCE        -- �����Q��
      , xx03_if_head_line_rec.LINE_JOURNAL_DESCRIPTION    -- ���l�i�d��j
      , xx03_if_head_line_rec.LINE_ORG_ID                 -- �I���OID
-- == 2016/12/06 11.5.10.2.12 Modified START ===============================================================
--      , NULL                                              -- ATTRIBUTE_CATEGORY
      , xx03_if_head_line_rec.LINE_ORG_ID                 -- ATTRIBUTE_CATEGORY
-- == 2016/12/06 11.5.10.2.12 Modified START ===============================================================
      , NULL                                              -- ATTRIBUTE1
      , NULL                                              -- ATTRIBUTE2
      , NULL                                              -- ATTRIBUTE3
      , NULL                                              -- ATTRIBUTE4
      , NULL                                              -- ATTRIBUTE5
      , NULL                                              -- ATTRIBUTE6
-- == 2016/12/06 11.5.10.2.12 Modified START ===============================================================
--      , NULL                                              -- ATTRIBUTE7
      , xx03_if_head_line_rec.LINE_ATTRIBUTE7             -- ATTRIBUTE7
-- == 2016/12/06 11.5.10.2.12 Modified START ===============================================================
      , NULL                                              -- ATTRIBUTE8
      , NULL                                              -- ATTRIBUTE9
      , NULL                                              -- ATTRIBUTE10
      , NULL                                              -- ATTRIBUTE11
      , NULL                                              -- ATTRIBUTE12
      , NULL                                              -- ATTRIBUTE13
      , NULL                                              -- ATTRIBUTE14
      , NULL                                              -- ATTRIBUTE15
      , xx00_global_pkg.user_id                           -- CREATED_BY
      , xx00_date_pkg.get_system_datetime_f               -- CREATION_DATE
      , xx00_global_pkg.user_id                           -- LAST_UPDATED_BY
      , xx00_date_pkg.get_system_datetime_f               -- LAST_UPDATE_DATE
      , xx00_global_pkg.login_id                          -- LAST_UPDATE_LOGIN
      , xx00_global_pkg.conc_request_id                   -- REQUEST_ID
      , xx00_global_pkg.prog_appl_id                      -- PROGRAM_APPLICATION_ID
      , xx00_global_pkg.conc_program_id                   -- PROGRAM_ID
      , xx00_date_pkg.get_system_datetime_f               -- PROGRAM_UPDATE_DATE
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
   * Description      : �����˗��̓��̓`�F�b�N(E-2)
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
-- ver 11.5.10.2.10F Del Start
--    -- ���F�ҏ��J�[�\��
---- Ver11.5.10.1.6 Chg Start
----    CURSOR xx03_approve_chk_cur(i_person_id NUMBER)
--    CURSOR xx03_approve_chk_cur(i_person_id NUMBER, i_val_dep VARCHAR2)
---- Ver11.5.10.1.6 Chg End
--    IS
--      SELECT
--        count('x') rec_cnt
--      FROM
--        XX03_APPROVER_PERSON_LOV_V xaplv
--      WHERE
--        xaplv.PERSON_ID = i_person_id
---- Ver11.5.10.1.6 Add Start
--      AND (   xaplv.PROFILE_VAL_DEP = 'ALL'
--           or xaplv.PROFILE_VAL_DEP = i_val_dep)
---- Ver11.5.10.1.6 Add End
--    ;
--    -- ���F�ҏ��J�[�\�����R�[�h�^
--    xx03_approve_chk_rec xx03_approve_chk_cur%ROWTYPE;
-- ver 11.5.10.2.10F Del End
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
-- ver 11.5.10.2.10F Chg Start
--      -- ���F�Җ������͂���Ă���ꍇ�͏��F�r���[�ɂčă`�F�b�N
---- Ver11.5.10.1.6 Chg Start
----      OPEN xx03_approve_chk_cur(xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID);
--      OPEN xx03_approve_chk_cur(xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID ,xx03_if_head_line_rec.HEAD_SLIP_TYPE_APP);
---- Ver11.5.10.1.6 Chg End
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
-- ver 11.5.10.2.10F Chg End
-- Ver11.5.10.1.5B Add End
    END IF;
--
-- ver 11.5.10.2.10 Add Start
    -- ����^�C�v�`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_TRANS_TYPE_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_TRANS_TYPE_ID) = '' ) THEN
      -- ����^�C�vID����̏ꍇ�͎���^�C�v���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08048'
        )
      );
    END IF;
-- ver 11.5.10.2.10 Add End
--
    -- �ڋq�`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_CUSTOMER_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_CUSTOMER_NAME) = '' ) THEN
      -- �ڋq����̏ꍇ�͌ڋq���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08029'
        )
      );
    END IF;
--
    -- �ڋq���Ə��`�F�b�N
    IF ( xx03_if_head_line_rec.HEAD_CUSTOMER_OFFICE_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_CUSTOMER_OFFICE_ID) = '' ) THEN
      -- �ڋq���Ə�����̏ꍇ�͌ڋq���Ə����̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08030'
        )
      );
    END IF;
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
-- ver 1.2 Change Start
    -- �x�����@�`�F�b�N
--    IF ( xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_NAME IS NULL
--           OR TRIM(xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_NAME) = '' ) THEN
    IF ( xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_ID) = '' ) THEN
      -- �x�����@����̏ꍇ�͎x�����@���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
--          'APP-XX03-08015'
          'APP-XX03-08031'
        )
      );
    END IF;
-- ver 1.2 Change End
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
    -- ver 11.5.10.2.10D Chg Start
    --IF ( xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE IS NULL
    --       OR TRIM(xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE) = '' ) THEN
    IF ( xx03_if_head_line_rec.HEAD_CHK_CURRENCY_CODE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_CHK_CURRENCY_CODE) = '' ) THEN
    -- ver 11.5.10.2.10D Chg End
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
    -- �O����[���`�[�ԍ��`�F�b�N
    IF (xx03_if_head_line_rec.HEAD_COMMITMENT_NUMBER IS NOT NULL
        AND (xx03_if_head_line_rec.HEAD_COM_TRX_NUMBER IS NULL
             OR TRIM(xx03_if_head_line_rec.HEAD_COM_TRX_NUMBER) = '' )) THEN
      -- �O����[���`�[����i�擾�ł��Ȃ��j�ꍇ�͓��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14058'
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
   * Description      : �����˗��̓��̓`�F�b�N(E-2)
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
-- ver 11.5.10.2.10 Chg Start
--    -- �������eID�`�F�b�N
    -- �������e���̃`�F�b�N(�}�X�^�ɖ���ID�����݂��Ȃ��Ă����R���͂��\)
-- ver 11.5.10.2.10 Del End
    IF ( xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE_NAME IS NULL ) THEN
      -- �������eID����̏ꍇ�͐������e���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08032'
        )
      );
    END IF;
--
    -- �P�ʃ`�F�b�N
      -- �P�ʂ���̏ꍇ�͒P�ʓ��̓G���[�\��
    IF ( xx03_if_head_line_rec.LINE_SLIP_LINE_UOM IS NULL ) AND
      ( xx03_if_head_line_rec.LINE_SLIP_LINE_UOM_NAME IS NOT NULL ) THEN
      -- �P�ʂ���ŒP�ʖ�����łȂ��ꍇ�͒P�ʓ��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08044'
        )
      );
    END IF;
--
    -- ���׏���Ŋz�`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT IS NULL ) THEN
      -- ����Ŋz����̏ꍇ�͏���Ŋz���̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08034'
        )
      );
    END IF;
--
-- ver 11.5.10.2.10H Add Start
    -- ���ה[�i���ԍ�����Byte�`�F�b�N
    IF LENGTHB(xx03_if_head_line_rec.LINE_SLIP_LINE_RECIEPT_NO) > 30 THEN
      -- ���ה[�i���ԍ���30Byte�𒴂���ꍇ�͓��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-13072'
        )
      );
    END IF;
-- ver 11.5.10.2.10H Add Start
--
-- ver 11.5.10.2.9 Add Start
    -- ���ה��l(����)����Byte�`�F�b�N
    IF LENGTHB(xx03_if_head_line_rec.LINE_SLIP_DESCRIPTION) > 30 THEN
      -- ���ה��l(����)��30Byte�𒴂���ꍇ�͓��̓G���[�\��
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-13071'
        )
      );
    END IF;
-- ver 11.5.10.2.9 Add Start
--
    -- �ŋ敪�`�F�b�N
    IF ( xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_CODE IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_CODE) = '' ) THEN
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
    -- Ver11.5.10.1.5C 2005/10/21 Add Start
    -- �ŋ敪����łȂ��ꍇ�̂݁A���͓��ŋ敪�Ɠ��͐ŋ敪�̓��Ńt���O�̈�v�`�F�b�N���s��
    ELSIF (  nvl(xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_FLAG ,'N')
        != nvl(xx03_if_head_line_rec.LINE_MST_TAX_FLAG       ,'N') ) THEN
      -- �X�e�[�^�X���G���[��
      gv_result := cv_result_error;
      -- �G���[�������Z
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08045',
          'TOK_XX03_LINE_TAX_NAME',
          xx03_if_head_line_rec.LINE_TAX_NAME
        )
      );
    -- Ver11.5.10.1.5C 2005/10/21 Add End
    END IF;
--
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
    in_commitment_amount IN  NUMBER,       --  3.�O���[�����z
    iv_cur_code          IN  VARCHAR2,     --  4.�ʉ݃R�[�h
    in_conversion_rate   IN  NUMBER,       --  5.���Z���[�g
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
    --�ʉ݃R�[�h���@�\�ʉ݂łȂ��ꍇ�͋��z�����[�g���Z���Ċ��Z�ύ��v���z�Z�b�g
    ln_accounted_amount := (in_total_item_amount + in_total_tax_amount) - in_commitment_amount;
    IF ( iv_cur_code != gv_cur_code ) THEN
      SELECT TO_NUMBER( TO_CHAR( ln_accounted_amount * in_conversion_rate
                                ,xx00_currency_pkg.get_format_mask(gv_cur_code, 38))
                       ,xx00_currency_pkg.get_format_mask(gv_cur_code, 38))
      INTO   ln_accounted_amount
      FROM   dual;
    END IF;
--
    -- �w�b�_���R�[�h�ɋ��z�Z�b�g
    UPDATE XX03_RECEIVABLE_SLIPS xrs
    SET    xrs.INV_ITEM_AMOUNT      = in_total_item_amount
         , xrs.INV_TAX_AMOUNT       = in_total_tax_amount
         , xrs.INV_AMOUNT           = (in_total_item_amount + in_total_tax_amount) - in_commitment_amount
         , xrs.INV_ACCOUNTED_AMOUNT = ln_accounted_amount
         , xrs.COMMITMENT_AMOUNT    = in_commitment_amount
    WHERE  xrs.RECEIVABLE_ID   = gn_receivable_id;
--
    -- �d�_�Ǘ��`�F�b�N
    xx03_deptinput_ar_check_pkg.set_account_approval_flag(
      gn_receivable_id,
      lv_app_upd,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
    IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      -- ���ʂ�����Ȃ�A�w�b�_���R�[�h�̏d�_�Ǘ��t���O���X�V
      UPDATE XX03_RECEIVABLE_SLIPS xrs
      SET    xrs.ACCOUNT_APPROVAL_FLAG = lv_app_upd    -- �d�_�Ǘ��t���O
      WHERE  xrs.RECEIVABLE_ID = gn_receivable_id;
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
    xx03_deptinput_ar_check_pkg.check_deptinput_ar(
      gn_receivable_id,
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
    ln_max_line          NUMBER := xx00_profile_pkg.value('VO_MAX_FETCH_SIZE'); -- �ő喾�׍s��
    lv_max_over_flg      VARCHAR2(1);   -- �ő喾�׍s�I�[�o�[�t���O
    ln_interface_id      NUMBER;        -- INTERFACE_ID
    ln_if_id_back        NUMBER;        -- INTERFACE_ID�O���R�[�h�d���`�F�b�N
    lv_if_id_new_flg     VARCHAR2(1);   -- INTERFACE_ID�ύX�t���O
    lv_first_flg         VARCHAR2(1);   -- �������R�[�h�t���O
    ln_total_item_amount NUMBER;        -- �{�̋��z���v
    ln_total_tax_amount  NUMBER;        -- �{�̐ŋ����v
    ln_commitment_amount NUMBER;        -- �O��[����
    lv_cur_code          VARCHAR2(15);  -- �ʉ݃R�[�h
    ln_conversion_rate   NUMBER;        -- ���Z���[�g
    ln_line_count        NUMBER;        -- ���׌����J�E���g
    ld_terms_date        DATE;          -- �x���\���
    lv_terms_flg         VARCHAR2(1);   -- �x���\����ύX�\�t���O
    ln_ent_amount        NUMBER;        -- ���z
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
    -- �V�X�e�����J�[�\���I�[�v��
    OPEN sys_tax_cur;
      FETCH sys_tax_cur INTO sys_tax_rec;
    CLOSE sys_tax_cur;
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
              ln_commitment_amount, --  3.�O��[�����z
              lv_cur_code,          --  4.�ʉ݃R�[�h
              ln_conversion_rate,   --  5.���Z���[�g
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
      END IF;
--
      -- ver 11.5.10.2.6B Chg Start
      ---- INTERFACE_ID����l�w�b�_���P���̎��̓w�b�_�G���[
      --IF (xx03_if_head_line_rec.CNT_REC_COUNT > 1) THEN
      -- INTERFACE_ID����l�w�b�_���P���̎��͂������͖���No�d�����̓w�b�_�G���[
      IF (   (xx03_if_head_line_rec.CNT_REC_COUNT > 1         )
          OR (xx03_if_head_line_rec.CNT2_LINE_SUM_NO_FLG = 'X') )THEN
      -- ver 11.5.10.2.6B Chg End
--
        -- �V�w�b�_�̏ꍇ�̓G���[���o��
        IF lv_if_id_new_flg = '1'  THEN
--
          -- ver 11.5.10.2.6B Chg Start
          ---- INTERFACE_ID����l�w�b�_���Q���ȏ�
          ---- �X�e�[�^�X���G���[��
          --gv_result := cv_result_error;
          ---- �G���[�������Z
          --gn_error_count := gn_error_count + 1;
          --
          ---- INTERFACE_ID�o��
          --xx00_file_pkg.output(
          --  xx00_message_pkg.get_msg(
          --    'XX03',
          --    'APP-XX03-08008',
          --    'TOK_XX03_INTERFACE_ID',
          --    xx03_if_head_line_rec.HEAD_INTERFACE_ID
          --  )
          --);
          ---- �G���[���o��
          --xx00_file_pkg.output(
          --  xx00_message_pkg.get_msg(
          --    'XX03',
          --    'APP-XX03-08006'
          --  )
          --);
--
          -- �X�e�[�^�X���G���[��
          gv_result := cv_result_error;
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
--
          -- INTERFACE_ID����l�w�b�_���Q���ȏ�
          IF (xx03_if_head_line_rec.CNT_REC_COUNT > 1) THEN
            -- �G���[�������Z
            gn_error_count := gn_error_count + 1;
            -- �G���[���o��
            xx00_file_pkg.output(
              xx00_message_pkg.get_msg(
                'XX03',
                'APP-XX03-08006'
              )
            );
          END IF;
--
          -- LINE��No����l���Q���ȏ゠��
          IF (xx03_if_head_line_rec.CNT2_LINE_SUM_NO_FLG = 'X') THEN
            -- �G���[�������Z
            gn_error_count := gn_error_count + 1;
            -- �G���[���o��
            xx00_file_pkg.output(
              xx00_message_pkg.get_msg(
                'XX03',
                'APP-XX03-08046'
              )
            );
          END IF;
          -- ver 11.5.10.2.6B Chg End
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
            -- �����\����擾(E-4)
            -- ===============================
            xx03_deptinput_ar_check_pkg.get_terms_date(
              xx03_if_head_line_rec.HEAD_TERMS_ID,
              xx03_if_head_line_rec.HEAD_INVOICE_DATE,
              ld_terms_date,
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
            ln_line_count,     -- ���׍s��
            ln_ent_amount,     --
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ���v���z�Z�o�p�ϐ����Z
        ln_total_item_amount := ln_total_item_amount + ln_ent_amount;
        ln_total_tax_amount  := ln_total_tax_amount  + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT;
--
        -- �[�����z�v�Z
        IF ( xx03_if_head_line_rec.HEAD_COMMITMENT_NUMBER IS NOT NULL ) THEN
          -- ���R�[�h�̏[�����z�ƁA�{�̋��z�{����Ŋz�̏����������[�����z�Ƃ���
          IF ( nvl(xx03_if_head_line_rec.HEAD_COM_COMMITMENT_AMOUNT,0) > (ln_total_item_amount + ln_total_tax_amount)) THEN
            ln_commitment_amount := ln_total_item_amount + ln_total_tax_amount;
          ELSE
            ln_commitment_amount := nvl(xx03_if_head_line_rec.HEAD_COM_COMMITMENT_AMOUNT,0);
          END IF;
        ELSE
          -- �[���`�[�Ȃ�
          ln_commitment_amount := 0;
        END IF;
--
        -- �ʉ݃R�[�h�E���Z���[�g
        lv_cur_code        := xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE;
        ln_conversion_rate := xx03_if_head_line_rec.HEAD_CONVERSION_RATE;
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
          ln_commitment_amount, --  3.�O��[�����z
          lv_cur_code,          --  4.�ʉ݃R�[�h
          ln_conversion_rate,   --  5.���Z���[�g
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


-- Ver11.5.10.1.5 2005/09/06 Change End
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
    -- ���݂̐������ԍ��擾
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --SELECT xsnv.TEMPORARY_CODE,
    --       xsnv.SLIP_NUMBER
    --  INTO lv_slip_code,
    --       ln_slip_number
    --  FROM XX03_SLIP_NUMBERS_V xsnv
    -- WHERE xsnv.APPLICATION_SHORT_NAME = cv_appl_AR_ID
    --   AND xsnv.NUM_TYPE = '0'
    --FOR UPDATE NOWAIT;
    SELECT xsn.TEMPORARY_CODE,
           xsn.SLIP_NUMBER
      INTO lv_slip_code,
           ln_slip_number
      FROM XX03_SLIP_NUMBERS xsn
     WHERE xsn.APPLICATION_SHORT_NAME = cv_appl_AR_ID
       AND xsn.NUM_TYPE = '0'
       AND xsn.ORG_ID = xx00_profile_pkg.value('ORG_ID')
    FOR UPDATE NOWAIT;
    -- Ver11.5.10.1.6D 2006/01/06 Change End
--
    -- �������ԍ����Z
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --UPDATE XX03_SLIP_NUMBERS_V xsnv
    --   SET xsnv.SLIP_NUMBER = ln_slip_number + in_add_count
    -- WHERE xsnv.APPLICATION_SHORT_NAME = cv_appl_AR_ID
    --   AND xsnv.NUM_TYPE = '0';
    UPDATE XX03_SLIP_NUMBERS xsn
       SET xsn.SLIP_NUMBER = ln_slip_number + in_add_count
     WHERE xsn.APPLICATION_SHORT_NAME = cv_appl_AR_ID
       AND xsn.NUM_TYPE = '0'
       AND xsn.ORG_ID = xx00_profile_pkg.value('ORG_ID');
    -- Ver11.5.10.1.6D 2006/01/06 Change End
--
    -- �߂�l�Z�b�g
    ov_slip_code   := lv_slip_code;
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
      rollback;
    WHEN global_api_expt THEN   -- *** ���ʊ֐���O�n���h�� ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
      rollback;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
      rollback;
    WHEN OTHERS THEN  -- *** OTHERS��O�n���h�� ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
      rollback;
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
--
    -- *** ���[�J���ϐ� ***
    ln_update_count NUMBER;     -- �X�V����
    lv_slip_code VARCHAR2(10);  -- �������R�[�h
    ln_slip_number NUMBER;      -- �������ԍ�
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �X�V�Ώێ擾�J�[�\��
    CURSOR update_record_cur
    IS
      SELECT xrs.RECEIVABLE_ID
        FROM XX03_RECEIVABLE_SLIPS xrs
       WHERE xrs.REQUEST_ID = xx00_global_pkg.conc_request_id
      ORDER BY xrs.RECEIVABLE_ID;
--
    -- ���O�o�͗p�J�[�\��
    CURSOR outlog_cur(pv_source VARCHAR2,
                        pn_request_id NUMBER)
    IS
      SELECT xrsi.INTERFACE_ID   as INTERFACE_ID,
             xrs.RECEIVABLE_NUM  as RECEIVABLE_NUM        -- �`�[�ԍ�
        FROM XX03_RECEIVABLE_SLIPS_IF xrsi,
             XX03_RECEIVABLE_SLIPS    xrs
       WHERE xrsi.REQUEST_ID    = pn_request_id
         AND xrsi.SOURCE        = pv_source
         AND xrsi.RECEIVABLE_ID = xrs.RECEIVABLE_ID;
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
      SELECT COUNT(xrs.RECEIVABLE_ID)
        INTO ln_update_count
        FROM XX03_RECEIVABLE_SLIPS xrs
       WHERE xrs.REQUEST_ID = xx00_global_pkg.conc_request_id;
--
      -- �������ԍ��擾
      update_slip_number(
        ln_update_count,              -- IN  �X�V����
        lv_slip_code,                 -- OUT �������R�[�h
        ln_slip_number,               -- OUT �������ԍ�
        lv_errbuf,                    -- OUT �G���[�E���b�Z�[�W
        lv_retcode,                   -- OUT ���^�[���E�R�[�h
        lv_errmsg);                   -- OUT ���[�U�[�E�G���[�E���b�Z�[�W
--
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
        RAISE global_process_expt;
      END IF;
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
        -- �������ԍ����Z
        ln_slip_number := ln_slip_number + 1;
--
        -- �������ԍ��X�V
        UPDATE XX03_RECEIVABLE_SLIPS xrs
           SET xrs.RECEIVABLE_NUM = lv_slip_code || TO_CHAR(ln_slip_number)
         WHERE xrs.RECEIVABLE_ID = update_record_rec.RECEIVABLE_ID;
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
            outlog_rec.RECEIVABLE_NUM
          )
        );
--
      END LOOP out_log_loop;
      CLOSE outlog_cur;
--
      -- ver 11.5.10.2.5 Del Start
      ---- �C���^�[�t�F�[�X�e�[�u���f�[�^�폜
      --DELETE FROM XX03_RECEIVABLE_SLIPS_IF xrsi
      --      WHERE xrsi.REQUEST_ID = in_request_id
      --        AND xrsi.SOURCE     = iv_source;
      --
      --DELETE FROM XX03_RECEIVABLE_SLIPS_LINE_IF xrsli
      --      WHERE xrsli.REQUEST_ID = in_request_id
      --        AND xrsli.SOURCE     = iv_source;
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
END XX034RI002C;
/
