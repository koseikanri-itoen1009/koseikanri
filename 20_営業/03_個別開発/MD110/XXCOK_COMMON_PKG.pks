CREATE OR REPLACE PACKAGE xxcok_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcok_common_pkg(spec)
 * Description      : �ʊJ���̈�E���ʊ֐�
 * MD.070           : MD070_IPO_COK_���ʊ֐�
 * Version          : 1.1
 *
 * Program List
 * --------------------------   ------------------------------------------------------------
 *  Name                         Description
 * --------------------------   ------------------------------------------------------------
 *  get_acctg_calendar_p         ��v�J�����_�擾
 *  get_next_year_p              ����v�N�x�擾
 *  get_set_of_books_info_p      ��v������擾
 *  get_close_date_p             ���߁E�x�����擾
 *  get_emp_code_f               �]�ƈ��R�[�h�擾
 *  check_acctg_period_f         ��v���ԃ`�F�b�N
 *  get_operating_day_f          �ғ����擾
 *  get_sales_staff_code_f       �S���c�ƈ��R�[�h�擾
 *  get_wholesale_req_est_p      �≮�������Ϗƍ�
 *  get_companies_code_f         ��ƃR�[�h�擾
 *  get_department_code_f        ��������R�[�h�擾
 *  get_batch_name_f             �o�b�`���擾
 *  get_slip_number_f            �`�[�ԍ��擾
 *  check_year_migration_f       �N���ڍs���m��`�F�b�N
 *  get_code_combination_id_f    CCID�擾
 *  get_code_combination_id_f    CCID�`�F�b�N
 *  put_message_f                ���b�Z�[�W�o��
 *  get_base_code_f              �������_�R�[�h�擾
 *  split_csv_data_p             CSV�����񕪊�
 *  get_bill_to_cust_code_f      ������ڋq�R�[�h�擾
 *  get_wholesale_req_est_type_f �≮���������Ϗ��ˍ��X�e�[�^�X�擾
 *  get_uom_conversion_qty_f     ��P�ʊ��Z���擾
 *  get_directory_path_f         �f�B���N�g���p�X�擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/31    1.0   T.OSADA          �V�K�쐬
 *  2009/02/06    1.1   K.YAMAGUCHI      [��QCOK_022] �f�B���N�g���p�X�擾�ǉ�
 *  
 *****************************************************************************************/
  -- ===============================
  -- �O���[�o���^
  -- ===============================
  -- ������CSV(VARCHAR2)�f�[�^���i�[����z��
  TYPE g_split_csv_tbl IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
  --���ʊ֐��v���V�[�W���E��v�J�����_�擾
  PROCEDURE get_acctg_calendar_p(
    ov_errbuf                   OUT VARCHAR2             -- �G���[�o�b�t�@
  , ov_retcode                  OUT VARCHAR2             -- ���^�[���R�[�h
  , ov_errmsg                   OUT VARCHAR2             -- �G���[���b�Z�[�W
  , in_set_of_books_id          IN  NUMBER               -- ��v����ID
  , iv_application_short_name   IN  VARCHAR2             -- �A�v���P�[�V�����Z�k��
  , id_object_date              IN  DATE                 -- �Ώۓ�
  , iv_adjustment_period_flag   IN  VARCHAR2 DEFAULT 'N' -- �����t���O
  , on_period_year              OUT NUMBER               -- ��v�N�x
  , ov_period_name              OUT VARCHAR2             -- ��v���Ԗ�
  , ov_closing_status           OUT VARCHAR2             -- �X�e�[�^�X
  );
  --���ʊ֐��v���V�[�W���E����v�N�x�擾
  PROCEDURE get_next_year_p(
    ov_errbuf                   OUT VARCHAR2                              -- �G���[�E�o�b�t�@
  , ov_retcode                  OUT VARCHAR2                              -- ���^�[���E�R�[�h
  , ov_errmsg                   OUT VARCHAR2                              -- �G���[�E���b�Z�[�W
  , in_set_of_books_id          IN  gl_sets_of_books.set_of_books_id%TYPE -- ��v����ID
  , in_period_year              IN  gl_periods.period_year%TYPE           -- ��v�N�x
  , on_next_period_year         OUT gl_periods.period_year%TYPE           -- ����v�N�x
  , od_next_start_date          OUT gl_periods.start_date%TYPE            -- ����v�N�x�����
  );
  --���ʊ֐��v���V�[�W���E��v������擾
  PROCEDURE get_set_of_books_info_p(
    ov_errbuf                   OUT VARCHAR2            -- �G���[�E�o�b�t�@
  , ov_retcode                  OUT VARCHAR2            -- ���^�[���R�[�h
  , ov_errmsg                   OUT VARCHAR2            -- �G���[�E���b�Z�[�W
  , on_set_of_books_id          OUT NUMBER              -- ��v����ID
  , ov_set_of_books_name        OUT VARCHAR2            -- ��v���떼
  , on_chart_acct_id            OUT NUMBER              -- ����̌nID
  , ov_period_set_name          OUT VARCHAR2            -- �J�����_��
  , on_aff_segment_cnt          OUT NUMBER              -- AFF�Z�O�����g��`��
  , ov_currency_code            OUT VARCHAR2            -- �@�\�ʉ݃R�[�h
  );
  --���ʊ֐��v���V�[�W���E���߁E�x�����擾
  PROCEDURE get_close_date_p(
    ov_errbuf                   OUT VARCHAR2            -- �G���[�E�o�b�t�@
  , ov_retcode                  OUT VARCHAR2            -- ���^�[���R�[�h
  , ov_errmsg                   OUT VARCHAR2            -- �G���[�E���b�Z�[�W
  , id_proc_date                IN  DATE DEFAULT NULL   -- ������(�Ώۓ�)
  , iv_pay_cond                 IN  VARCHAR2            -- �x������(IN)
  , od_close_date               OUT DATE                -- ���ߓ�(OUT)
  , od_pay_date                 OUT DATE                -- �x����(OUT)
  );
  --���ʊ֐��t�@���N�V�����E�]�ƈ��R�[�h�擾
  FUNCTION get_emp_code_f(
    in_user_id                  IN NUMBER               -- ���[�UID
  )
  RETURN VARCHAR2;                                      --�]�ƈ��R�[�h
  --���ʊ֐��t�@���N�V�����E��v���ԃ`�F�b�N
  FUNCTION check_acctg_period_f(
    in_set_of_books_id          IN NUMBER               -- ��v����ID
  , id_proc_date                IN DATE                 -- ������(�Ώۓ�)
  , iv_application_short_name   IN VARCHAR2             -- �A�v���P�[�V�����Z�k��
  )
  RETURN BOOLEAN;                                       -- BOOLEAN�^ TRUE/FALSE
  --���ʊ֐��t�@���N�V�����E�c�Ɠ��擾
  FUNCTION get_operating_day_f(
    id_proc_date                IN DATE                 -- ������ 
  , in_days                     IN NUMBER               -- ���� 
  , in_proc_type                IN NUMBER               -- �����敪 
  , in_calendar_type            IN NUMBER DEFAULT 0     -- �J�����_�[�敪
  )
  RETURN DATE;                                          -- �c�Ɠ�
  --���ʊ֐��t�@���N�V�����E�S���c�ƈ��R�[�h�擾
  FUNCTION get_sales_staff_code_f(
    iv_customer_code            IN VARCHAR2             -- �ڋq�R�[�h 
  , id_proc_date                IN DATE                 -- ������ 
  )
  RETURN VARCHAR2;                                      -- �S���c�ƈ��R�[�h
  --���ʊ֐��v���V�[�W���E�≮�������Ϗƍ�
  PROCEDURE get_wholesale_req_est_p(
    ov_errbuf                   OUT VARCHAR2            -- �G���[�o�b�t�@
  , ov_retcode                  OUT VARCHAR2            -- ���^�[���R�[�h
  , ov_errmsg                   OUT VARCHAR2            -- �G���[���b�Z�[�W
  , iv_wholesale_code           IN  VARCHAR2            -- �≮�Ǘ��R�[�h
  , iv_sales_outlets_code       IN  VARCHAR2            -- �≮������R�[�h
  , iv_item_code                IN  VARCHAR2            -- �i�ڃR�[�h
  , in_demand_unit_price        IN  NUMBER              -- �����P��
  , iv_demand_unit_type         IN  VARCHAR2            -- �����P��
  , iv_selling_month            IN  VARCHAR2            -- ����Ώ۔N��
  , ov_estimated_no             OUT VARCHAR2            -- ���Ϗ�No.
  , on_quote_line_id            OUT NUMBER              -- ����ID
  , ov_emp_code                 OUT VARCHAR2            -- �S���҃R�[�h
  , on_market_amt               OUT NUMBER              -- ���l
  , on_allowance_amt            OUT NUMBER              -- �l��(���߂�)
  , on_normal_store_deliver_amt OUT NUMBER              -- �ʏ�X�[
  , on_once_store_deliver_amt   OUT NUMBER              -- ����X�[
  , on_net_selling_price        OUT NUMBER              -- NET���i
  , ov_estimated_type           OUT VARCHAR2            -- ���ϋ敪
  , on_backmargin_amt           OUT NUMBER              -- �̔��萔��
  , on_sales_support_amt        OUT NUMBER              -- �̔����^��
  );
  --���ʊ֐��t�@���N�V�����E�≮���������Ϗ��ˍ��X�e�[�^�X�擾
  FUNCTION get_wholesale_req_est_type_f(
    iv_wholesale_code           IN  VARCHAR2            -- �≮�Ǘ��R�[�h
  , iv_sales_outlets_code       IN  VARCHAR2            -- �≮������R�[�h
  , iv_item_code                IN  VARCHAR2            -- �i�ڃR�[�h
  , in_demand_unit_price        IN  NUMBER              -- �����P��
  , iv_demand_unit_type         IN  VARCHAR2            -- �����P��
  , iv_selling_month            IN  VARCHAR2            -- ����Ώ۔N��
  )
  RETURN VARCHAR2;                                      -- �X�e�[�^�X
  --���ʊ֐��t�@���N�V�����E��ƃR�[�h�擾
  FUNCTION get_companies_code_f(
    iv_customer_code            IN  VARCHAR2            -- �ڋq�R�[�h
  )
  RETURN VARCHAR2;                                      -- ��ƃR�[�h
  --���ʊ֐��t�@���N�V�����E��������R�[�h�擾
  FUNCTION get_department_code_f(
    in_user_id                  IN  NUMBER              -- ���[�U�[ID
  )
  RETURN VARCHAR2;                                      -- ��������R�[�h
  --���ʊ֐��t�@���N�V�����E�o�b�`���擾
  FUNCTION get_batch_name_f(
    iv_category_name            IN  VARCHAR2            -- �d��J�e�S��
  )
  RETURN VARCHAR2;                                      -- �o�b�`��
  --���ʊ֐��t�@���N�V�����E�`�[�ԍ��擾
  FUNCTION get_slip_number_f(
    iv_package_name             IN  VARCHAR2            -- �p�b�P�[�W��
  )
  RETURN VARCHAR2;                                      -- �`�[�ԍ�
  --���ʊ֐��t�@���N�V�����E�N���ڍs���m��`�F�b�N
  FUNCTION check_year_migration_f(
    in_year                     IN  NUMBER              -- �N�x
  )
  RETURN BOOLEAN;                                       -- �u�[���l
  --���ʊ֐��t�@���N�V�����ECCID�擾
  FUNCTION get_code_combination_id_f(
    id_proc_date                IN  DATE                -- ������
  , iv_segment1                 IN  VARCHAR2            -- ��ЃR�[�h
  , iv_segment2                 IN  VARCHAR2            -- ����R�[�h
  , iv_segment3                 IN  VARCHAR2            -- ����ȖڃR�[�h
  , iv_segment4                 IN  VARCHAR2            -- �⏕�ȖڃR�[�h
  , iv_segment5                 IN  VARCHAR2            -- �ڋq�R�[�h
  , iv_segment6                 IN  VARCHAR2            -- ��ƃR�[�h
  , iv_segment7                 IN  VARCHAR2            -- �\���P�R�[�h
  , iv_segment8                 IN  VARCHAR2            -- �\���Q�R�[�h
  )
  RETURN NUMBER;                                        -- ����Ȗ�ID
  --���ʊ֐��t�@���N�V�����E���b�Z�[�W�o��
  FUNCTION put_message_f(
    in_which                    IN  NUMBER              -- �o�͋敪
  , iv_message                  IN  VARCHAR2            -- ���b�Z�[�W
  , in_new_line                 IN  NUMBER              -- ���s
  )
  RETURN BOOLEAN;                                       -- BOOLEAN�^ TRUE/FALSE
  --���ʊ֐��t�@���N�V�����E�������_�R�[�h�擾
  FUNCTION get_base_code_f(
    id_proc_date                IN  DATE                -- ������
  , in_user_id                  IN  NUMBER              -- ���[�U�[ID
  )
  RETURN VARCHAR2;                                      -- �������_
  --���ʊ֐��v���V�[�W���ECSV�����񕪊�
  PROCEDURE split_csv_data_p(
    ov_errbuf                   OUT VARCHAR2            -- �G���[�o�b�t�@
  , ov_retcode                  OUT VARCHAR2            -- ���^�[���R�[�h
  , ov_errmsg                   OUT VARCHAR2            -- �G���[���b�Z�[�W
  , iv_csv_data                 IN  VARCHAR2            -- CSV������
  , on_csv_col_cnt              OUT PLS_INTEGER         -- CSV���ڐ�
  , ov_split_csv_tab            OUT g_split_csv_tbl     -- CSV�����f�[�^
  );
  --���ʊ֐��t�@���N�V�����E������ڋq�R�[�h�擾
  FUNCTION get_bill_to_cust_code_f(
    iv_ship_to_cust_code        IN VARCHAR2             -- �o�א�ڋq�R�[�h
  )
  RETURN VARCHAR2;                                      -- ������ڋq�R�[�h
  --���ʊ֐��t�@���N�V�����ECCID���݃`�F�b�N
  FUNCTION check_code_combination_id_f(
    iv_segment1                 IN  VARCHAR2            -- ��ЃR�[�h
  , iv_segment2                 IN  VARCHAR2            -- ����R�[�h
  , iv_segment3                 IN  VARCHAR2            -- ����ȖڃR�[�h
  , iv_segment4                 IN  VARCHAR2            -- �⏕�ȖڃR�[�h
  , iv_segment5                 IN  VARCHAR2            -- �ڋq�R�[�h
  , iv_segment6                 IN  VARCHAR2            -- ��ƃR�[�h
  , iv_segment7                 IN  VARCHAR2            -- �\���P�R�[�h
  , iv_segment8                 IN  VARCHAR2            -- �\���Q�R�[�h
  )
  RETURN BOOLEAN;                                       -- �u�[���l
  --���ʊ֐��t�@���N�V�����E��P�ʊ��Z���擾
  FUNCTION get_uom_conversion_qty_f(
    iv_item_code                IN  VARCHAR2            -- �i�ڃR�[�h
  , iv_uom_code                 IN  VARCHAR2            -- �P�ʃR�[�h
  , in_quantity                 IN  NUMBER              -- ���Z�O����
  )
  RETURN NUMBER;                                        -- ��P�ʊ��Z�㐔��
  --���ʊ֐��t�@���N�V�����E�f�B���N�g���p�X�擾
  FUNCTION get_directory_path_f(
    iv_directory_name              IN  VARCHAR2         -- �f�B���N�g����
  )
  RETURN VARCHAR2;                                      -- �f�B���N�g���p�X
--
END xxcok_common_pkg;
/
