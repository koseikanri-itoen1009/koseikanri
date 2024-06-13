CREATE OR REPLACE PACKAGE XXCFR_COMMON_PKG--(�ύX)
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcfr_common_pkg(spec)
 * Description      : 
 * MD.050           : �Ȃ�
 * Version          : 1.3
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_user_dept             F    VAR    ���O�C�����[�U��������擾�֐�
 *  chk_invoice_all_dept      F    VAR    �������S�Џo�͌�������֐�
 *  put_log_param             P           ���̓p�����[�^�l���O�o�͏���
 *  get_table_comment         F    VAR    �e�[�u���R�����g�擾����
 *  get_user_profile_name     F    VAR    ���[�U�v���t�@�C�����擾����
 *  get_cust_account_name     F    VAR    �ڋq���̎擾�֐�
 *  get_col_comment           F    VAR    ���ڃR�����g�擾����
 *  lookup_dictionary         F    VAR    ���{�ꎫ���Q�Ɗ֐�����
 *  get_date_param_trans      F    VAR    ���t�p�����[�^�ϊ��֐�
 *  csv_out                   P           OUT�t�@�C���o�͏���
 *  get_base_target_tel_num   F    VAR    �������_�S���d�b�ԍ��擾�֐�
 *  get_receive_updatable     F    VAR    ������� �ڋq�ύX�\����
-- Modify 2010.07.09 Ver1.2 Start
 *  awi_ship_code             P           ARWebInquiry�p �[�i��ڋq�R�[�h�l���X�g
-- Modify 2010.07.09 Ver1.2 End
 *  get_invoice_regnum        F    VAR    �C���{�C�X�o�^�ԍ��擾�i����o�R�j�֐�
 *  get_invoice_regnum        F    VAR    �C���{�C�X�o�^�ԍ��擾�֐�
 *  get_company_code          F    VAR    ��ЃR�[�h�擾�i����o�R�j�֐�
 *  conv_company_code         F    VAR    ��ЃR�[�h�ϊ��֐�
 *  get_fin_dept_code         F    VAR    �����o������R�[�h�擾�֐�
 *  get_invoice_svf_info      P           ������SVF���擾�֐�
 *  get_invoice_issuer_info   P           �K�i���������s���Ǝҏ��擾�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-10-16   1.0    SCS ���b       �V�K�쐬
 *  2008-10-28   1.0    SCS ���� �א�    �ڋq���̎擾�֐��ǉ�
 *  2008-10-29   1.0    SCS ���� ��      ���̓p�����[�^�l���O�o�͊֐��֐��ǉ�
 *  2008-11-10   1.0    SCS ���� ��      ���̓p�����[�^�l���O�o�͊֐��C��
 *  2008-11-10   1.0    SCS ���� ��      ���ڃR�����g�擾�����֐��ǉ�
 *  2008-11-12   1.0    SCS ���� ��      ���{�ꎫ���Q�Ɗ֐������ǉ�
 *  2008-11-13   1.0    SCS ���� �א�    ���t�p�����[�^�ϊ��֐��ǉ�
 *  2008-11-18   1.0    SCS �g�� ���i    OUT�t�@�C���o�͏����ǉ�
 *  2008-12-22   1.0    SCS ���� �א�    �������_�S���d�b�ԍ��擾�֐��ǉ�
 *  2010-03-31   1.1    SCS ���� �q��    ��Q�uE_�{�ғ�_02092�v�Ή�
 *                                       �V�Kfunction�uget_receive_updatable�v��ǉ�
 *  2010-07-09   1.2    SCS �A�� �^���l  ��Q�uE_�{�ғ�_01990�v�Ή�
 *                                       �V�KPrucedure�uawi_ship_code�v��ǉ�
 *  2023-10-24   1.3    SCSK ��R �m��   ��Q�uE_�{�ғ�_19496�Ή��v�Ή�
 *                                       �V�KFunction�uget_invoice_regnum�v�uget_company_code�v
 *                                        �uconv_company_code�v�uget_fin_dept_code�v��ǉ�
 *                                       �V�KPrucedure�uget_invoice_svf_info�v
 *                                        �uget_invoice_issuer_info�v��ǉ�
 *
 *****************************************************************************************/
--
  --���O�C�����[�U��������擾�֐�
  FUNCTION get_user_dept(
    in_user_id       IN     NUMBER,           -- 1.���[�UID
    id_get_date      IN     DATE)             -- 2.�擾���t
  RETURN VARCHAR2;                            -- ���O�C�����[�U��������
  --
  --�������S�Џo�͌�������֐�
  FUNCTION chk_invoice_all_dept(
    iv_user_dept_code IN    VARCHAR2,         -- 1.��������R�[�h
    iv_invoice_type   IN    VARCHAR2)         -- 2.�������^�C�v
  RETURN VARCHAR2;                            -- ���茋��
  --
  --���̓p�����[�^�l���O�o�͏���
  PROCEDURE put_log_param(
    iv_which                IN  VARCHAR2 DEFAULT 'OUTPUT',  -- �o�͋敪
    iv_conc_param1          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�P
    iv_conc_param2          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�Q
    iv_conc_param3          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�R
    iv_conc_param4          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�S
    iv_conc_param5          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�T
    iv_conc_param6          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�U
    iv_conc_param7          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�V
    iv_conc_param8          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�W
    iv_conc_param9          IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�X
    iv_conc_param10         IN  VARCHAR2 DEFAULT NULL,      -- �R���J�����g�p�����[�^�P�O
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  ;
  --
  --�e�[�u���R�����g�擾����
  FUNCTION get_table_comment(
    iv_table_name          IN  VARCHAR2 )       -- �e�[�u����
  RETURN VARCHAR2;                              -- �e�[�u���R�����g
  --
  --�v���t�@�C�����擾����
  FUNCTION get_user_profile_name(
    iv_profile_name        IN  VARCHAR2 )       -- �v���t�@�C����
  RETURN VARCHAR2;                              -- ���[�U�v���t�@�C����
  --
  --�ڋq���̎擾�֐�
  FUNCTION get_cust_account_name(
    iv_account_number  IN   VARCHAR2,         -- 1.�ڋq�R�[�h
    iv_kana_judge_type IN   VARCHAR2 )        -- 2.�J�i�����f�敪(0:��������, 1:�J�i��)
  RETURN VARCHAR2;
  --
  --���ڃR�����g�擾����
  FUNCTION get_col_comment(
    iv_table_name          IN  VARCHAR2,        -- �e�[�u����
    iv_column_name         IN  VARCHAR2 )       -- ���ږ�
  RETURN VARCHAR2;                              -- ���ڃR�����g
  --���{�ꎫ���Q�Ə���
  FUNCTION lookup_dictionary(
    iv_loopup_type_prefix  IN  VARCHAR2,        -- �Q�ƃ^�C�v�̐ړ����i�A�v���P�[�V�����Z�k���Ɠ����j
    iv_keyword             IN  VARCHAR2 )       -- �L�[���[�h
  RETURN VARCHAR2;                              -- ���{����e
  --
  --���t�p�����[�^�ϊ��֐�
  FUNCTION get_date_param_trans(
    iv_date_param          IN  VARCHAR2 )       -- ���t�l�p�����[�^(������^)
  RETURN DATE;                                  -- ���t�l�p�����[�^(���t�^)
  --
  --OUT�t�@�C���o�͏���
  PROCEDURE  csv_out(
    in_request_id     IN   NUMBER,    -- 1.�v��ID
    iv_lookup_type    IN   VARCHAR2,  -- 2.�Q�ƃ^�C�v
    in_rec_cnt        IN   NUMBER,    -- 3.���R�[�h����
    ov_errbuf         OUT  VARCHAR2,  -- 4.�o�̓��b�Z�[�W
    ov_retcode        OUT  VARCHAR2,  -- 5.���^�[���R�[�h
    ov_errmsg         OUT  VARCHAR2)  -- 6.���[�U���b�Z�[�W
  ;
  --
  --�������_�S���d�b�ԍ��擾�֐�
  FUNCTION get_base_target_tel_num(
    iv_bill_acct_code  IN   VARCHAR2          -- 1.������ڋq�R�[�h
  )
  RETURN VARCHAR2;
  --
  --�����ڋq�ύX�\����
  FUNCTION get_receive_updatable(
    in_cash_receipt_id IN NUMBER,   -- 1.����ID
    iv_gl_date IN VARCHAR2          -- 2.GL�L����
  )
  RETURN VARCHAR2;
-- Modify 2010.07.09 Ver1.2 Start
  --
  -- ARWebInquiry�p �[�i��ڋq�R�[�h�l���X�g
  PROCEDURE awi_ship_code(
    p_sql_type         IN     VARCHAR2,
    p_sql              IN OUT VARCHAR2,
    p_list_filter_item IN     VARCHAR2,
    p_sort_item        IN     VARCHAR2,
    p_sort_method      IN     VARCHAR2,
    p_segment_id       IN     NUMBER,
    p_child_condition  IN     VARCHAR2,
    p_parent_condition IN     VARCHAR2 DEFAULT NULL)
  ;
-- Modify 2010.07.09 Ver1.2 End
--
-- Ver1.3 ADD START
  -- �C���{�C�X�o�^�ԍ��擾�i����o�R�j�֐�
  FUNCTION get_invoice_regnum(
    iv_dept_code        IN   VARCHAR2                     -- 1.����R�[�h
   ,in_set_of_books_id  IN   NUMBER                       -- 2.��v����ID
   ,id_base_date        IN   DATE                         -- 3.���
   ,id_get_date         IN   DATE DEFAULT TRUNC(SYSDATE)  -- 4.�擾���t
  )
  RETURN VARCHAR2;
--
  -- �C���{�C�X�o�^�ԍ��擾�֐�
  FUNCTION get_invoice_regnum(
    iv_company_code     IN   VARCHAR2                     -- 1.��ЃR�[�h
   ,id_get_date         IN   DATE DEFAULT TRUNC(SYSDATE)  -- 2.�擾���t
  )
  RETURN VARCHAR2;
--
  -- ��ЃR�[�h�擾�i����o�R�j�֐�
  FUNCTION get_company_code(
    iv_dept_code        IN   VARCHAR2                     -- 1.����R�[�h
   ,in_set_of_books_id  IN   NUMBER                       -- 2.��v����ID
   ,id_base_date        IN   DATE                         -- 3.���
  )
  RETURN VARCHAR2;
--
  -- ��ЃR�[�h�ϊ��֐�
  FUNCTION conv_company_code(
    iv_company_code     IN   VARCHAR2                     -- 1.��ЃR�[�h
   ,id_base_date        IN   DATE                         -- 2.���
  )
  RETURN VARCHAR2;
--
  -- �����o������R�[�h�擾�֐�
  FUNCTION get_fin_dept_code(
    iv_company_code     IN   VARCHAR2                     -- 1.��ЃR�[�h
   ,id_base_date        IN   DATE                         -- 2.���
  )
  RETURN VARCHAR2;
--
  -- ������SVF���擾�֐�
  PROCEDURE get_invoice_svf_info(
    iv_file_id          IN   VARCHAR2                     -- 1.���[ID
   ,iv_invoice_type     IN   VARCHAR2                     -- 2.�������^�C�v
   ,iv_company_code     IN   VARCHAR2                     -- 3.��ЃR�[�h
   ,id_get_date         IN   DATE DEFAULT TRUNC(SYSDATE)  -- 4.�擾���t
   ,ov_frm_file         OUT  VARCHAR2                     -- 5.�t�H�[���l���t�@�C����
   ,ov_vrq_file         OUT  VARCHAR2                     -- 6.�N�G���[�l���t�@�C����
   ,ov_errbuf           OUT  VARCHAR2                     -- 7.�G���[���b�Z�[�W
   ,ov_retcode          OUT  VARCHAR2                     -- 8.���^�[���R�[�h
   ,ov_errmsg           OUT  VARCHAR2                     -- 9.���[�U�[�G���[���b�Z�[�W
  );
--
  -- �K�i���������s���Ǝҏ��擾�֐�
  PROCEDURE get_invoice_issuer_info(
    iv_company_code     IN   VARCHAR2                     -- 1.��ЃR�[�h
   ,id_get_date         IN   DATE DEFAULT TRUNC(SYSDATE)  -- 2.�擾���t
   ,ov_regnum           OUT  VARCHAR2                     -- 3.�o�^�ԍ�
   ,ov_issuer           OUT  VARCHAR2                     -- 4.���s���Ǝ�(��Ж�)
   ,ov_errbuf           OUT  VARCHAR2                     -- 5.�G���[���b�Z�[�W
   ,ov_retcode          OUT  VARCHAR2                     -- 6.���^�[���R�[�h
   ,ov_errmsg           OUT  VARCHAR2                     -- 7.���[�U�[�G���[���b�Z�[�W
  );
-- Ver1.3 ADD END
--
END XXCFR_COMMON_PKG;--(�ύX)
/
