CREATE OR REPLACE PACKAGE BODY xxwsh400002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400002C(body)
 * Description      : �ڋq��������̏o�׈˗������쐬
 * MD.050/070       : �o�׈˗�                        (T_MD050_BPO_400)
 *                    �ڋq��������̏o�׈˗������쐬  (T_MD070_BPO_40B)
 * Version          : 1.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  pro_err_list_make      P �G���[���X�g�쐬
 *  pro_get_cus_option     P �֘A�f�[�^�擾                     (B-1)
 *  pro_param_chk          P ���̓p�����[�^�`�F�b�N             (B-2)
 *  pro_get_head_line      P �o�׈˗��C���^�[�t�F�[�X���擾   (B-3)
 *  pro_interface_chk      P �C���^�[�t�F�C�X���`�F�b�N       (B-4)
 *  pro_day_time_chk       P �ғ���/���[�h�^�C���`�F�b�N        (B-5)
 *  pro_item_chk           P ���׏��}�X�^���݃`�F�b�N         (B-6)
 *  pro_xsr_chk            P �����\�����݃`�F�b�N               (B-7)
 *  pro_total_we_ca        P ���v�d��/���v�e�ώZ�o              (B-8)
 *  pro_ship_y_n_chk       P �o�׉ۃ`�F�b�N                   (B-9)
 *  pro_lines_create       P �󒍖��׃A�h�I�����R�[�h�쐬       (B-10)
 *  pro_load_eff_chk       P �ύڌ����`�F�b�N                   (B-11)
 *  pro_headers_create     P �󒍃w�b�_�A�h�I�����R�[�h�쐬     (B-12)
 *  pro_order_ins_del      P �󒍃A�h�I���o��                   (B-13)
 *  pro_purge_del          P �p�[�W����                         (B-14)
 *  submain                P ���C�������v���V�[�W��
 *  main                   P �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/31    1.0   Tatsuya Kurata   �V�K�쐬
 *  2008/04/23    1.1   Tatsuya Kurata   �����ύX�v��#65�Ή�
 *  2008/06/04    1.2   �Γn  ���a       [pro_item_chk]IF����鐔�ʂ����̂܂܃Z�b�g����悤�ύX
 *                                       [pro_ship_y_n_chk]�o�׉ۃ`�F�b�N�ُ�I��������ǉ�
 *                                       [pro_order_ins_del]�ŐV�t���O��ǉ�
 *  2008/06/04    1.3   �Ŗ�  ���\       �ύڌ����`�F�b�N�C��
 *  2008/06/05    1.4   �Γn  ���a       [pro_ship_y_n_chk]�o�׉ۃ`�F�b�N�ŏo�׌�ID��n���ύX
 *  2008/06/05    1.5   �Γn  ���a       �폜�t���O�Ƀf�t�H���g�l���Z�b�g
 *                                       �P�w�b�_�ڂ͖��ׂ��폜����Ȃ����ߏC��
 *  2008/06/10    1.6   �Γn  ���a       �G���[���X�g�̐��l���ڑO�X�y�[�X���߂��폜
 *                                       xxwsh_common910_pkg�̋A��l������C��
 *  2008/06/13    1.7   �Γn  ���a       ���ʊ֐��ُ�I�����̃G���[���X�g���Ē���
 *                                       ���׏d�ʂ̌v�Z���@���C��
 *  2008/06/17    1.8   �Γn  ���a       ��{�d�ʁE��{�e�ς̃Z�b�g���f���C��
 *  2008/06/19    1.9   �V��  �`��       �����ύX�v��#143�Ή�
 *  2008/06/24    1.10  �Γn  ���a       ST�s�#247�A#284�Ή�
 *  2008/06/27    1.11  �Γn  ���a       ST�s�#318�Ή�
 *  2008/07/01    1.12  �Ŗ�  ���\       ST�s�#247�C�Ή�
 *  2008/07/04    1.13  �㌴  ���D       ST�s�#392�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
--
--################################  �Œ蕔 END   ###############################
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
  -- ���͂o�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD
    (
      in_base        VARCHAR2(30)   -- ���͋��_
     ,jur_base       VARCHAR2(30)   -- �Ǌ����_
    );
--
  -- �o�׈˗��C���^�[�t�F�[�X���擾�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_head_line IS RECORD
    ( h_id         xxwsh_shipping_headers_if.header_id%TYPE             -- �w�b�_ID
     ,p_s_code     xxwsh_shipping_headers_if.party_site_code%TYPE       -- �o�א�
     ,ship_ins     xxwsh_shipping_headers_if.shipping_instructions%TYPE -- �E�v
     ,c_po_num     xxwsh_shipping_headers_if.cust_po_number%TYPE        -- �ڋq����
     ,o_r_ref      xxwsh_shipping_headers_if.order_source_ref%TYPE      -- �󒍃\�[�X�Q��
     ,ship_date    xxwsh_shipping_headers_if.schedule_ship_date%TYPE    -- �o�ח\���
     ,arr_date     xxwsh_shipping_headers_if.schedule_arrival_date%TYPE -- ���ח\���
     ,lo_code      xxwsh_shipping_headers_if.location_code%TYPE         -- �o�׌��ۊǏꏊ
     ,h_s_branch   xxwsh_shipping_headers_if.head_sales_branch%TYPE     -- �Ǌ����_
     ,data_type    xxwsh_shipping_headers_if.data_type%TYPE             -- �f�[�^�^�C�v
     ,arr_t_from   xxwsh_shipping_headers_if.arrival_time_from%TYPE     -- ���׎���From
     ,order_class  xxwsh_shipping_headers_if.ordered_class%TYPE         -- �˗��敪
     ,ord_i_code   xxwsh_shipping_lines_if.orderd_item_code%TYPE        -- �i��
     ,ord_quant    xxwsh_shipping_lines_if.orderd_quantity%TYPE         -- ����
     ,in_sales_br  xxwsh_shipping_headers_if.input_sales_branch%TYPE    -- ���͋��_
    );
  TYPE tab_data_head_line IS TABLE OF rec_head_line INDEX BY PLS_INTEGER;
--
  -- �G���[���b�Z�[�W�o�͗p
  TYPE rec_err_msg IS RECORD
    (
      err_msg     VARCHAR2(10000)
    );
  TYPE tab_data_err_msg IS TABLE OF rec_err_msg INDEX BY BINARY_INTEGER;
--
  -- IF�e�[�u���폜�p
  TYPE tab_data_del_if IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;
  gn_normal_cnt    NUMBER;
  gn_error_cnt     NUMBER;
  gn_warn_cnt      NUMBER;
--
--################################  �Œ蕔 END   ###############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  err_expt                 EXCEPTION;
  err_header_expt          EXCEPTION;     -- �G���[���b�Z�[�W�쐬�㔻��
  lock_error_expt          EXCEPTION;     -- ���b�N�G���[
--
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���萔
  -- ==================================================
  gv_pkg_name        CONSTANT VARCHAR2(15) := 'xxwsh400002c';          -- �p�b�P�[�W��
  -- �v���t�@�C��
  gv_prf_m_org       CONSTANT VARCHAR2(50) := 'XXCMN_MASTER_ORG_ID';   -- XXCMN:�}�X�^�g�D
  -- �G���[���b�Z�[�W�R�[�h
  gv_application     CONSTANT VARCHAR2(5)  := 'XXWSH';                 -- �A�v���P�[�V����
  gv_err_cik         CONSTANT VARCHAR2(20) := 'APP-XXCMN-10121';
                                                     -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  gv_err_pro         CONSTANT VARCHAR2(20) := 'APP-XXWSH-11051';
                                                     -- �v���t�@�C���擾�G���[���b�Z�[�W
  gv_err_lock        CONSTANT VARCHAR2(20) := 'APP-XXWSH-11052';
                                                     -- ���b�N�G���[���b�Z�[�W
  gv_err_p_name      CONSTANT VARCHAR2(20) := 'APP-XXWSH-11054';
                                                     -- ���̓p�����[�^�}�X�^���o�^�G���[���b�Z�[�W
  gv_err_para        CONSTANT VARCHAR2(20) := 'APP-XXWSH-11055';
                                                     -- ���̓p�����[�^���ݒ�G���[���b�Z�[�W
  gv_err_no_con      CONSTANT VARCHAR2(20) := 'APP-XXWSH-11056';
                                                     -- ���̓p�����[�^�s�K���G���[���b�Z�[�W
  -- �g�[�N��
  gv_tkn_prof_name   CONSTANT VARCHAR2(10) := 'PROF_NAME';
  gv_tkn_lookup_type CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';
  gv_tkn_meaning     CONSTANT VARCHAR2(10) := 'MEANING';
  gv_tkn_para_name   CONSTANT VARCHAR2(15) := 'PARAMETER_NAME';
  gv_tkn_kyoten      CONSTANT VARCHAR2(10) := 'KYOTEN';
  -- �g�[�N�������b�Z�[�W
  gv_tkn_msg_org     CONSTANT VARCHAR2(20) := 'XXCMN:�}�X�^�g�D';
  gv_tkn_msg_in_b    CONSTANT VARCHAR2(8)  := '���͋��_';
  gv_tkn_msg_ju_b    CONSTANT VARCHAR2(8)  := '�Ǌ����_';
  -- �N�C�b�N�R�[�h
  gv_ship_method     CONSTANT VARCHAR2(20) := 'XXCMN_SHIP_METHOD';
  gv_tr_status       CONSTANT VARCHAR2(25) := 'XXWSH_TRANSACTION_STATUS';
  gv_notif_status    CONSTANT VARCHAR2(20) := 'XXWSH_NOTIF_STATUS';
  gv_shipping_class  CONSTANT VARCHAR2(20) := 'XXWSH_SHIPPING_CLASS';
--
  gv_all_item        CONSTANT VARCHAR2(7)  := 'ZZZZZZZ'; -- �S�i��
  gv_order_c_code    CONSTANT VARCHAR2(5)  := 'ORDER';   -- �󒍃J�e�S���R�[�h
--
  gv_yes             CONSTANT VARCHAR2(1)  := 'Y';
  gv_no              CONSTANT VARCHAR2(1)  := 'N';
  gv_0               CONSTANT VARCHAR2(1)  := '0';
  gv_1               CONSTANT VARCHAR2(1)  := '1';
  gv_2               CONSTANT VARCHAR2(1)  := '2';
  gv_3               CONSTANT VARCHAR2(1)  := '3';
  gv_4               CONSTANT VARCHAR2(1)  := '4';
  gv_5               CONSTANT VARCHAR2(1)  := '5';
  gv_6               CONSTANT VARCHAR2(1)  := '6';
  gv_9               CONSTANT VARCHAR2(1)  := '9';
  gv_10              CONSTANT VARCHAR2(2)  := '10';
  gv_01              CONSTANT VARCHAR2(2)  := '01';
  gv_99              CONSTANT VARCHAR2(2)  := '99';
  gv_delete          CONSTANT VARCHAR2(1)  := 'D';
--
  gv_ship_st         CONSTANT VARCHAR2(6)  := '���͒�';
  gv_notice_st       CONSTANT VARCHAR2(6)  := '���ʒm';
  -- �G���[���X�g���ږ�
  gv_name_kind       CONSTANT VARCHAR2(4)  := '���';
  gv_name_dec        CONSTANT VARCHAR2(4)  := '�m��';
  gv_name_req_no     CONSTANT VARCHAR2(8)  := '�˗��m��';
  gv_name_ship_to    CONSTANT VARCHAR2(6)  := '�z����';
  gv_name_descrip    CONSTANT VARCHAR2(4)  := '�E�v';
  gv_name_cust_pono  CONSTANT VARCHAR2(12) := '�ڋq�����ԍ�';
  gv_name_ship_date  CONSTANT VARCHAR2(6)  := '�o�ɓ�';
  gv_name_arr_date   CONSTANT VARCHAR2(4)  := '����';
  gv_name_ship_from  CONSTANT VARCHAR2(6)  := '�o�׌�';
  gv_name_item_a     CONSTANT VARCHAR2(4)  := '�i��';
  gv_name_qty        CONSTANT VARCHAR2(4)  := '����';
  gv_name_err_msg    CONSTANT VARCHAR2(16) := '�G���[���b�Z�[�W';
  gv_name_err_clm    CONSTANT VARCHAR2(10) := '�G���[����';
  gv_line            CONSTANT VARCHAR2(25) := '-------------------------';
  -- �G���[���X�g�\�����e
  gv_msg_hfn         CONSTANT VARCHAR2(2)  := '�|';
  gv_msg_err         CONSTANT VARCHAR2(6)  := '�G���[';
  gv_msg_war         CONSTANT VARCHAR2(4)  := '�x��';
  gv_msg_1           CONSTANT VARCHAR2(28) := '�w�o�א�x�ݒ肳��Ă��܂���';
  gv_msg_2           CONSTANT VARCHAR2(36) := '�w�󒍃\�[�X�Q�Ɓx�ݒ肳��Ă��܂���';
  gv_msg_3           CONSTANT VARCHAR2(32) := '�w�o�ח\����x�ݒ肳��Ă��܂���';
  gv_msg_4           CONSTANT VARCHAR2(32) := '�w���ח\����x�ݒ肳��Ă��܂���';
  gv_msg_5           CONSTANT VARCHAR2(36) := '�w�o�׌��ۊǏꏊ�x�ݒ肳��Ă��܂���';
  gv_msg_6           CONSTANT VARCHAR2(30) := '�w�Ǌ����_�x�ݒ肳��Ă��܂���';
  gv_msg_7           CONSTANT VARCHAR2(34) := '�w�f�[�^�^�C�v�x�ݒ肳��Ă��܂���';
  gv_msg_8           CONSTANT VARCHAR2(26) := '�w�i�ځx�ݒ肳��Ă��܂���';
  gv_msg_9           CONSTANT VARCHAR2(26) := '�w���ʁx�ݒ肳��Ă��܂���';
  gv_msg_10          CONSTANT VARCHAR2(46) := '�w�o�א�x���p�[�e�B�}�X�^�ɓo�^����Ă��܂���';
  gv_msg_11          CONSTANT VARCHAR2(50) := '�w�o�׌��x��OPM�ۊǏꏊ�}�X�^�ɓo�^����Ă��܂���';
  gv_msg_12          CONSTANT VARCHAR2(48) := '�w�Ǌ����_�x���p�[�e�B�}�X�^�ɓo�^����Ă��܂���';
  gv_msg_13          CONSTANT VARCHAR2(34) := '�w���i�敪�x���擾�ł��܂���ł���';
  gv_msg_14          CONSTANT VARCHAR2(68) :=
                             '�w�˗��敪�x�ɑ΂���󒍃^�C�v���󒍃^�C�v�}�X�^�ɓo�^����Ă��܂���';
  gv_msg_15          CONSTANT VARCHAR2(52) := '�w���~�q�\���t���O�x�Ɂu0�v�ȊO���Z�b�g����Ă��܂�';
  gv_msg_16          CONSTANT VARCHAR2(32) := '���ח\����͉ғ����ł͂���܂���';
  gv_msg_17          CONSTANT VARCHAR2(32) := '�o�ח\����͉ғ����ł͂���܂���';
  gv_msg_18          CONSTANT VARCHAR2(16) := '���[�h�^�C���Z�o';
  gv_msg_19          CONSTANT VARCHAR2(30) := '�z�����[�h�^�C���𖞂����܂���';
  gv_msg_20          CONSTANT VARCHAR2(34) := '���Y�������[�h�^�C���𖞂����܂���';
  gv_msg_21          CONSTANT VARCHAR2(26) := '�݌ɉ�v���ԃN���[�Y�G���[';
  gv_msg_22          CONSTANT VARCHAR2(30) := '�i�ڃ}�X�^�ɓo�^����Ă��܂���';
  gv_msg_23          CONSTANT VARCHAR2(26) := '�o�׉\�i�ڂł͂���܂���';
  gv_msg_24          CONSTANT VARCHAR2(48) := '�w����Ώۋ敪�x�Ɂu1�v�ȊO���Z�b�g����Ă��܂�';
  gv_msg_25          CONSTANT VARCHAR2(40) := '�w�p�~�敪�x�ɁuD�v���Z�b�g����Ă��܂�';
  gv_msg_26          CONSTANT VARCHAR2(42) := '�w���敪�x�Ɂu0�v�ȊO���Z�b�g����Ă��܂�';
  gv_msg_27          CONSTANT VARCHAR2(52) := '�i�ڃ}�X�^�Ƀp���b�g����ő�i�����o�^����Ă��܂���';
  gv_msg_28          CONSTANT VARCHAR2(36) := '�i�ڃ}�X�^�ɔz�����o�^����Ă��܂���';
  gv_msg_29          CONSTANT VARCHAR2(34) := '�������[�g�Ƃ��ēo�^����Ă��܂���';
  gv_msg_30          CONSTANT VARCHAR2(42) := '����v��ɂ����āA�o�׉\���𒴂��Ă��܂�';
  gv_msg_31          CONSTANT VARCHAR2(50) := '�o�א�����(���i��)�ɂ����ďo�׉\���𒴂��Ă��܂�';
  gv_msg_32          CONSTANT VARCHAR2(50) := '�o�א�����(������)�ɂ����ďo�׉\���𒴂��Ă��܂�';
  gv_msg_33          CONSTANT VARCHAR2(62) :=
                             '�o�א�����(������)�ɂ����ďo�ח\������o�ג�~�����߂��Ă��܂�';
  gv_msg_34          CONSTANT VARCHAR2(48) := '�v�揤�i����v��ɂ����ďo�׉\���𒴂��Ă��܂�';
  gv_msg_35          CONSTANT VARCHAR2(40) := '�w���ʁx���w�z���x�̐����{�ł͂���܂���';
  gv_msg_36          CONSTANT VARCHAR2(44) := '�w���ʁx���w�o�ד����x�̐����{�ł͂���܂���';
  gv_msg_37          CONSTANT VARCHAR2(40) := '�w���ʁx���w�����x�̐����{�ł͂���܂���';
  gv_msg_38          CONSTANT VARCHAR2(32) := '�p���b�g�ő喇���𒴉߂��Ă��܂�';
  gv_msg_39          CONSTANT VARCHAR2(16) := '�ύڃI�[�o�[�ł�';
  gv_msg_40          CONSTANT VARCHAR2(46) := '�d�ʗe�ϋ敪���قȂ��Ă���i�ڂ��܂܂�Ă��܂�';
  gv_msg_41          CONSTANT VARCHAR2(56) :=
                             '�Ώۂ̈˗�No�f�[�^���X�e�[�^�X�m��ς݈ȏ�œo�^�ς݂ł�';
  gv_msg_42          CONSTANT VARCHAR2(20) := '�ő�z���敪�G���[';
  gv_msg_43          CONSTANT VARCHAR2(26) := '�����ΏۊO�̏o�Ɍ��q�ɂł�';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate         DATE;              -- �V�X�e�����ݓ��t
  gv_err_flg         VARCHAR2(1);       -- �G���[�m�F�p�t���O
  gv_err_sts         VARCHAR2(1);       -- ���ʃG���[���b�Z�[�W �I��ST�m�F�pF
  gv_name_m_org      VARCHAR2(20);      -- �}�X�^�g�D
  gv_del_if_flg      VARCHAR2(1);       -- IF�e�[�u���폜�Ώۃt���O
--
  -- WHO�J�����擾�p
  gn_created_by      NUMBER;            -- �쐬��
  gd_creation_date   DATE;              -- �쐬��
  gd_last_upd_date   DATE;              -- �ŏI�X�V��
  gn_last_upd_by     NUMBER;            -- �ŏI�X�V��
  gn_last_upd_login  NUMBER;            -- �ŏI�X�V���O�C��
  gn_request_id      NUMBER;            -- �v��ID
  gn_prog_appl_id    NUMBER;            -- �v���O�����A�v���P�[�V����ID
  gn_prog_id         NUMBER;            -- �v���O����ID
  gd_prog_upd_date   DATE;              -- �v���O�����X�V��
--
  gv_err_report      VARCHAR2(5000);
--
  gd_arr_work_day    DATE;              -- �ғ���(����)
  gd_shi_work_day    DATE;              -- �ғ���(�o��)
  gd_de_past_day     DATE;              -- �ғ������t(�߁E�z��)
  gd_past_day        DATE;              -- �ғ������t(�߁E���Y)
  gv_req_no          VARCHAR2(12);      -- �̔Ԃ���No
  gv_leadtime        VARCHAR2(20);      -- ���Y����LT/����ύXLT
  gv_delivery_lt     VARCHAR2(20);      -- �z�����[�h�^�C��
  gv_max_kbn         VARCHAR2(2);       -- �ő�z���敪
  gv_opm_c_p         VARCHAR2(6);       -- OPM�݌ɉ�v���� CLOSE�ő�N��
  gv_wei_kbn         VARCHAR2(1);       -- �d�ʗe�ϋ敪(B-12��r�p)
  gv_over_kbn        VARCHAR2(1);       -- �ύڃI�[�o�[�敪
  gv_ship_way        VARCHAR2(2);       -- �o�ו��@
  gv_mix_ship        VARCHAR2(2);       -- ���ڔz���敪
  gv_new_order_no    VARCHAR2(12);      -- �˗�No(12���p)
  gn_drink_we        NUMBER;            -- �h�����N�ύڏd��
  gn_leaf_we         NUMBER;            -- ���[�t�ύڏd��
  gn_drink_ca        NUMBER;            -- �h�����N�ύڗe��
  gn_leaf_ca         NUMBER;            -- ���[�t�ύڗe��
  gn_prt_max         NUMBER;            -- �p���b�g�ő喇��
  gn_ttl_we          NUMBER;            -- ���v�d��
  gn_ttl_ca          NUMBER;            -- ���v�e��
  gn_ttl_prt_we      NUMBER;            -- ���v�p���b�g�d��
  gn_detail_we       NUMBER;            -- ���׏d��
  gn_detail_ca       NUMBER;            -- ���חe��
  gn_ship_amount     NUMBER;            -- �o�גP�ʊ��Z��
  gn_we_loading      NUMBER;            -- �d�ʐύڌ���
  gn_ca_loading      NUMBER;            -- �e�ϐύڌ���
  gn_we_dammy        NUMBER;            -- �d�ʐύڌ���(�_�~�[)
  gn_ca_dammy        NUMBER;            -- �e�ϐύڌ���(�_�~�[)
  gn_item_amount     NUMBER;            -- ����
--
  gn_i               NUMBER;            -- LOOP�J�E���g�p
  gn_headers_seq     NUMBER;            -- �󒍃w�b�_�A�h�I��ID_SEQ
  gn_lines_seq       NUMBER;            -- �󒍖��׃A�h�I��ID_SEQ
--
  gn_cut             NUMBER DEFAULT 0;  -- �G���[���b�Z�[�W�p�J�E���g
  gn_line_number     NUMBER DEFAULT 0;  -- ���הԍ�
  gn_p_max_case_am   NUMBER DEFAULT 0;  -- �p���b�g����ő�P�[�X��
  gn_case_total      NUMBER DEFAULT 0;  -- �P�[�X�����v
  gn_pallet_am       NUMBER DEFAULT 0;  -- �p���b�g��
  gn_step_am         NUMBER DEFAULT 0;  -- �i��
  gn_case_am         NUMBER DEFAULT 0;  -- �P�[�X��
  gn_pallet_co_am    NUMBER DEFAULT 0;  -- �p���b�g����
  gn_pallet_t_c_am   NUMBER DEFAULT 0;  -- �p���b�g���v����
  gn_ttl_ship_am     NUMBER DEFAULT 0;  -- �o�גP�ʊ��Z��
  gn_h_ttl_weight    NUMBER DEFAULT 0;  -- �ύڏd�ʍ��v
  gn_h_ttl_capa      NUMBER DEFAULT 0;  -- �ύڗe�ύ��v
  gn_h_ttl_pallet    NUMBER DEFAULT 0;  -- ���v�p���b�g�d��
  gn_basic_we        NUMBER DEFAULT 0;  -- ��{�d��
  gn_basic_ca        NUMBER DEFAULT 0;  -- ��{�e��
  gn_ttl_amount      NUMBER DEFAULT 0;  -- ���v����
--
  gn_sh_h_cnt        NUMBER DEFAULT 0;  -- �o�׈˗��C���^�[�t�F�C�X�w�b�_����
  gn_req_cnt         NUMBER DEFAULT 0;  -- �o�׈˗��쐬����(�˗��m���P��)
  gn_line_cnt        NUMBER DEFAULT 0;  -- �o�׈˗��쐬���׌���(�˗����גP��)
--
  gv_small_qty_flg   NUMBER DEFAULT 0;  -- �����敪�t���O
--
  ord_l_all        xxwsh_order_lines_all%ROWTYPE;                   -- �󒍖��׃A�h�I���o�^�p����
  ord_h_all        xxwsh_order_headers_all%ROWTYPE;                 -- �󒍃w�b�_�A�h�I���o�^�p����
--
  gr_h_id          xxwsh_shipping_headers_if.header_id%TYPE;               -- �w�b�_ID
  gr_o_r_ref       xxwsh_shipping_headers_if.order_source_ref%TYPE;        -- �󒍃\�[�X�Q��
  gr_ship_st       xxcmn_lookup_values2_v.lookup_code%TYPE;                -- �o�׈˗��X�e�[�^�X
  gr_notice_st     xxcmn_lookup_values2_v.lookup_code%TYPE;                -- �ʒm�X�e�[�^�X
  gr_odr_type      xxwsh_oe_transaction_types2_v.transaction_type_id%TYPE; -- �󒍃^�C�vID
  gr_o_ship_div    xxcmn_locations_v.other_shipment_div%TYPE;          -- �����_�o�׈˗��쐬�ۋ敪
--
  gr_p_site_id     xxcmn_party_sites_v.party_site_id%TYPE;                 -- �o�א�ID
  gr_c_acc_num     xxcmn_parties_v.cust_account_id%TYPE;                   -- �ڋqID
  gr_party_num     xxcmn_parties_v.party_number%TYPE;                      -- �ڋq
  gr_cus_c_code    xxcmn_parties_v.customer_class_code%TYPE;               -- �ڋq�敪
  gr_cus_en_flag   xxcmn_parties_v.cust_enable_flag%TYPE;                  -- ���~�q�\���t���O
--
  gr_ship_id       xxcmn_item_locations_v.inventory_location_id%TYPE;      -- �ۊǒIID
  gr_a_p_flag      xxcmn_item_locations_v.allow_pickup_flag%TYPE;          -- �o�׈����Ώۃt���O
  gr_fre_mover     xxcmn_item_locations_v.frequent_mover%TYPE;             -- ��\�^�����
--
  gr_party_number  xxcmn_carriers_v.party_number%TYPE;                     -- ��\�^�����
  gr_party_id      xxcmn_carriers_v.party_id%TYPE;                         -- ��\�^�����ID
--
  gr_skbn          xxcmn_item_categories4_v.prod_class_code%TYPE;          -- ���i�敪
  gr_wei_kbn       xxcmn_item_mst_v.weight_capacity_class%TYPE;            -- �d�ʗe�ϋ敪
--
  gr_i_item_id     xxcmn_item_mst2_v.inventory_item_id%TYPE;               -- �i��ID
  gr_item_um       xxcmn_item_mst2_v.item_um%TYPE;                         -- �P��
  gr_conv_unit     xxcmn_item_mst2_v.conv_unit%TYPE;                       -- ���o�Ɋ��Z�P��
  gr_case_am       xxcmn_item_mst2_v.num_of_cases%TYPE;                    -- ����
  gr_item_skbn     xxcmn_item_categories4_v.prod_class_code%TYPE;          -- ���i�敪
  gr_item_kbn      xxcmn_item_categories4_v.item_class_code%TYPE;          -- �i�ڋ敪
  gr_max_p_step    xxcmn_item_mst2_v.max_palette_steps%TYPE;               -- �p���b�g����ő�i��
  gr_del_qty       xxcmn_item_mst2_v.delivery_qty%TYPE;                    -- �z��
  gr_i_wei_kbn     xxcmn_item_mst2_v.weight_capacity_class%TYPE;           -- �d�ʗe�ϋ敪
  gr_out_kbn       xxcmn_item_mst2_v.ship_class%TYPE;                      -- �o�׋敪
  gr_ship_am       xxcmn_item_mst2_v.num_of_deliver%TYPE;                  -- �o�ד���
  gr_sale_kbn      xxcmn_item_mst2_v.sales_div%TYPE;                       -- ����Ώۋ敪
  gr_end_kbn       xxcmn_item_mst2_v.obsolete_class%TYPE;                  -- �p�~�敪
  gr_rit_kbn       xxcmn_item_mst2_v.rate_class%TYPE;                      -- ���敪
--
  gr_ord_he_id     xxwsh_order_headers_all.order_header_id%TYPE;           -- �󒍃w�b�_�A�h�I��ID
  gr_req_status    xxwsh_order_headers_all.req_status%TYPE;                -- �X�e�[�^�X
--
  gr_param         rec_param_data;                        -- ���̓p�����[�^
  gt_head_line     tab_data_head_line;                    -- �o�׈˗��C���^�[�t�F�[�X���擾�f�[�^
  gt_err_msg       tab_data_err_msg;                      -- �G���[���b�Z�[�W�o�͗p
  gt_del_if        tab_data_del_if;                       -- IF�e�[�u���폜�p
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Procedure Name   : pro_err_list_make
   * Description      : �G���[���X�g�쐬
   ***********************************************************************************/
  PROCEDURE pro_err_list_make
    (
      iv_kind          IN VARCHAR2     --   �G���[���
     ,iv_dec           IN VARCHAR2     --   �m�菈���ł̃`�F�b�N
     ,iv_req_no        IN VARCHAR2     --   �˗�No
     ,iv_kyoten        IN VARCHAR2     --   �Ǌ����_
     ,iv_ship_to       IN VARCHAR2     --   �z����
     ,iv_description   IN VARCHAR2     --   �E�v
     ,iv_cust_pono     IN VARCHAR2     --   �ڋq�����ԍ�
     ,iv_ship_date     IN VARCHAR2     --   �o�ɓ�
     ,iv_arrival_date  IN VARCHAR2     --   ����
     ,iv_ship_from     IN VARCHAR2     --   �o�׌�
     ,iv_item          IN VARCHAR2     --   �i��
     ,in_qty           IN NUMBER       --   ����
     ,iv_err_msg       IN VARCHAR2     --   �G���[���b�Z�[�W
     ,iv_err_clm       IN VARCHAR2     --   �G���[����
     ,ov_errbuf       OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_err_list_make'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_err_msg        VARCHAR2(10000);
    lv_ship_date      VARCHAR2(10);
    ln_qty            NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���ʂ�NULL�̏ꍇ�A�O�\��
    IF (in_qty IS NULL) THEN
      ln_qty := NVL(in_qty,0);
    ELSE
      ln_qty := in_qty;
    END IF;
    ---------------------------------
    -- ���ʃG���[���b�Z�[�W�̍쐬  --
    ---------------------------------
    -- �e�[�u���J�E���g
    gn_cut := gn_cut + 1;
--
    lv_err_msg := iv_kind      || CHR(9) || iv_dec       || CHR(9) || iv_req_no       || CHR(9) ||
                  iv_kyoten    || CHR(9) || iv_ship_to   || CHR(9) || iv_description  || CHR(9) ||
                  iv_cust_pono || CHR(9) || iv_ship_date || CHR(9) || iv_arrival_date || CHR(9) ||
                  iv_ship_from || CHR(9) || iv_item      || CHR(9) ||
                  TO_CHAR(ln_qty,'FM999,999,990.000')    || CHR(9) ||
                  iv_err_msg   || CHR(9) || iv_err_clm;
    -- ���ʃG���[���b�Z�[�W�i�[
    gt_err_msg(gn_cut).err_msg  := lv_err_msg;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_err_list_make;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_cus_option
   * Description      : �֘A�f�[�^�擾 (B-1)
   ***********************************************************************************/
  PROCEDURE pro_get_cus_option
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_cus_option'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- WHO�J�����擾
    gn_created_by     := FND_GLOBAL.USER_ID;           -- �쐬��
    gd_creation_date  := gd_sysdate;                   -- �쐬��
    gn_last_upd_by    := FND_GLOBAL.USER_ID;           -- �ŏI�X�V��
    gd_last_upd_date  := gd_sysdate;                   -- �ŏI�X�V��
    gn_last_upd_login := FND_GLOBAL.LOGIN_ID;          -- �ŏI�X�V���O�C��
    gn_request_id     := FND_GLOBAL.CONC_REQUEST_ID;   -- �v��ID
    gn_prog_appl_id   := FND_GLOBAL.PROG_APPL_ID;      -- �v���O�����A�v���P�[�V����ID
    gn_prog_id        := FND_GLOBAL.CONC_PROGRAM_ID;   -- �v���O����ID
    gd_prog_upd_date  := gd_sysdate;                   -- �v���O�����X�V��
--
    --------------------------------------------------
    -- �N�C�b�N�R�[�h����o�׈˗��X�e�[�^�X���擾
    --------------------------------------------------
    BEGIN
--
      -- �o�׈˗��X�e�[�^�X[���͒�]�R�[�h���o
      SELECT xlvv.lookup_code
      INTO   gr_ship_st
      FROM   xxcmn_lookup_values_v  xlvv  -- �N�C�b�N�R�[�h��� V
      WHERE  xlvv.lookup_type = gv_tr_status
      AND    xlvv.meaning     = gv_ship_st;
--
    EXCEPTION
      -- �N�C�b�N�R�[�h�����݂��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( 'XXCMN'
                                                       ,gv_err_cik          -- �N�C�b�N�b�擾�G���[
                                                       ,gv_tkn_lookup_type  -- �g�[�N��
                                                       ,gv_tr_status
                                                       ,gv_tkn_meaning      -- �g�[�N��
                                                       ,gv_ship_st
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
    END;
--
    --------------------------------------------------
    -- �N�C�b�N�R�[�h����ʒm�X�e�[�^�X���擾
    --------------------------------------------------
    BEGIN
--
      -- �ʒm�X�e�[�^�X[���ʒm]�R�[�h���o
      SELECT xlvv.lookup_code
      INTO   gr_notice_st
      FROM   xxcmn_lookup_values_v  xlvv  -- �N�C�b�N�R�[�h��� V
      WHERE  xlvv.lookup_type = gv_notif_status
      AND    xlvv.meaning     = gv_notice_st;
--
    EXCEPTION
      -- �N�C�b�N�R�[�h�����݂��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( 'XXCMN'
                                                       ,gv_err_cik          -- �N�C�b�N�b�擾�G���[
                                                       ,gv_tkn_lookup_type  -- �g�[�N��
                                                       ,gv_notif_status
                                                       ,gv_tkn_meaning      -- �g�[�N��
                                                       ,gv_notice_st
                                                      )
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
    END;
--
    ------------------------------------------
    -- �v���t�@�C������}�X�^�g�D�擾
    ------------------------------------------
    gv_name_m_org := SUBSTRB(FND_PROFILE.VALUE(gv_prf_m_org),1,20);
    -- �擾�G���[��
    IF (gv_name_m_org IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application    -- 'XXWSH'
                                                     ,gv_err_pro        -- �v���t�@�C���擾�G���[
                                                     ,gv_tkn_prof_name  -- �g�[�N��
                                                     ,gv_tkn_msg_org    -- ���b�Z�[�W
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_get_cus_option;
--
  /**********************************************************************************
   * Procedure Name   : pro_param_chk
   * Description      : ���̓p�����[�^�`�F�b�N   (B-2)
   ***********************************************************************************/
  PROCEDURE pro_param_chk
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_param_chk'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_in_base_cnt     NUMBER;       -- ���͋��_�p
    ln_jur_base_cnt    NUMBER;       -- �Ǌ����_�p
    lv_party_number    VARCHAR2(4);  -- �g�D�ԍ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------------
    -- ���͂o�u���͋��_�v�̎擾
    ------------------------------------------
    -- �擾�G���[��
    IF (gr_param.in_base IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_para        -- �K�{���͂o���ݒ�G���[
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    -------------------------------------------------------------------------
    -- �ڋq�}�X�^�E�p�[�e�B�}�X�^�ɋ��_���o�^����Ă��邩�ǂ����̔���
    -------------------------------------------------------------------------
    SELECT COUNT (xcav.account_number)
    INTO   ln_in_base_cnt
    FROM   xxcmn_cust_accounts_v  xcav  -- �ڋq��� V
    WHERE  xcav.account_number      = gr_param.in_base   -- ���͂o[���͋��_]
    AND    xcav.customer_class_code = gv_1               -- '���_'�������u�R�[�h�敪�v
    AND    ROWNUM                   = 1;
--
    -- ���͂o[���͋��_]���ڋq�}�X�^�ɑ��݂��Ȃ��ꍇ
    IF (ln_in_base_cnt = 0) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_p_name      -- �}�X�^���o�^�G���[
                                                     ,gv_tkn_para_name   -- �g�[�N��
                                                     ,gv_tkn_msg_in_b    -- '���͋��_'
                                                     ,gv_tkn_kyoten      -- �g�[�N��
                                                     ,gr_param.in_base   -- ���͂o[���͋��_]
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    ---------------------------------------------------------------------------------------------
    -- ���͂o�u���͋��_�v�����O�C�����[�U�̏�������p�[�e�B�}�X�^.�g�D�ԍ��Ɠ��ꂩ�ǂ����̔���
    ---------------------------------------------------------------------------------------------
    -- ���O�C�����[�U�ɕR�Â����Ə��}�X�^.�����_�o�׈˗��쐬�ۋ敪�擾
    SELECT xlv.other_shipment_div
    INTO gr_o_ship_div
    FROM  fnd_user               fu   -- ���[�U�}�X�^     T
         ,per_all_assignments_f  paaf -- �]�ƈ������}�X�^ T
         ,xxcmn_locations_v      xlv  -- ���Ə����       V
    WHERE fu.user_id                 = FND_GLOBAL.USER_ID  -- ���O�C�����[�U�̃��[�UID
    AND   paaf.person_id             = fu.employee_id      -- �]�ƈ�ID
    AND   xlv.location_id            = paaf.location_id    -- ���Ə�ID
    AND   paaf.effective_start_date <= gd_sysdate          -- �L���J�n��
    AND   paaf.effective_end_date   >= gd_sysdate          -- �L���I����
    ;
--
    -- �����_�o�׈˗��쐬�ۋ敪 = '0'(�s��)�̏ꍇ
    IF (gr_o_ship_div = gv_0) THEN
      BEGIN
        SELECT xcav.party_number           -- �g�D�ԍ�
        INTO   lv_party_number
        FROM   fnd_user               fu   -- ���[�U�}�X�^     T
              ,per_all_assignments_f  paaf -- �]�ƈ������}�X�^ T
              ,xxcmn_locations_v      xlv  -- ���Ə����       V
              ,xxcmn_cust_accounts_v  xcav -- �ڋq���        V
        WHERE  xcav.customer_class_code   = gv_1                -- �ڋq�敪 ���_ '1'
        AND    fu.user_id                 = FND_GLOBAL.USER_ID  -- ���O�C�����[�U�̃��[�UID
        AND    paaf.person_id             = fu.employee_id      -- �]�ƈ�ID
        AND    xlv.location_id            = paaf.location_id    -- ���Ə�ID
        AND    xcav.party_number          = xlv.location_code   -- ���Ə��R�[�h
        AND    paaf.effective_start_date <= gd_sysdate          -- �L���J�n��
        AND    paaf.effective_end_date   >= gd_sysdate          -- �L���I����
        ;
        -- ���͂o�u���͋��_�v�̒l���A���O�C�����[�U�̏��������ƈقȂ�ꍇ�A�G���[
        IF (gr_param.in_base <> lv_party_number) THEN
          lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                         ,gv_err_no_con      -- ���͂o�s�K���G���[
                                                         ,gv_tkn_kyoten      -- �g�[�N��
                                                         ,gr_param.in_base   -- ���͂o[���͋��_]
                                                        )
                                                        ,1
                                                        ,5000);
          RAISE global_api_expt;
        END IF;
      EXCEPTION
        WHEN err_expt THEN
          RAISE global_api_expt;
      END;
    END IF;
--
    ------------------------------------------
    -- ���͂o�u�Ǌ����_�v�̎擾
    ------------------------------------------
    -- �擾�G���[��
    IF (gr_param.jur_base IS NOT NULL) THEN
      -- �ڋq�}�X�^�E�p�[�e�B�}�X�^�ɋ��_���o�^����Ă��邩�ǂ����̔���
      SELECT COUNT (xcav.account_number)
      INTO   ln_jur_base_cnt
      FROM   xxcmn_cust_accounts_v   xcav  -- �ڋq��� V
      WHERE  xcav.account_number      = gr_param.jur_base  -- ���͂o[�Ǌ����_]
      AND    xcav.customer_class_code = gv_1               -- '���_'�������u�R�[�h�敪�v
      AND    ROWNUM                   = 1;
    END IF;
--
    -- ���͂o[�Ǌ����_]���ڋq�}�X�^�ɑ��݂��Ȃ��ꍇ
    IF (ln_jur_base_cnt = 0) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application     -- 'XXWSH'
                                                     ,gv_err_p_name      -- �}�X�^���o�^�G���[
                                                     ,gv_tkn_para_name   -- �g�[�N��
                                                     ,gv_tkn_msg_ju_b    -- '�Ǌ����_'
                                                     ,gv_tkn_kyoten      -- �g�[�N��
                                                     ,gr_param.jur_base  -- ���͂o[�Ǌ����_]
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_param_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_get_head_line
   * Description      : �o�׈˗��C���^�[�t�F�[�X���擾   (B-3)
   ***********************************************************************************/
  PROCEDURE pro_get_head_line
    (
      ot_head_line    OUT NOCOPY tab_data_head_line    --   �擾���R�[�h�Q
     ,ov_errbuf       OUT VARCHAR2                     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      OUT VARCHAR2                     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       OUT VARCHAR2                     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_get_head_line'; -- �v���O������
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �s���b�N�p�J�[�\��
    CURSOR cur_get_lock
    IS
      SELECT xshi.header_id
      FROM  xxwsh_shipping_headers_if  xshi -- �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j
           ,xxwsh_shipping_lines_if    xsli -- �o�׈˗��C���^�t�F�[�X���ׁi�A�h�I���j
      WHERE xshi.data_type          = gv_10      -- [�o�׈˗�]��\���N�C�b�N�R�[�h�u�f�[�^�^�C�v�v
      AND   xshi.header_id          = xsli.header_id     -- �w�b�_ID
      AND   xshi.input_sales_branch = gr_param.in_base   -- ���͂o[���͋��_]
      FOR UPDATE NOWAIT
      ;
--
    -- ���͂o�u���͋��_�v�̂݃f�[�^�����݂��Ă���ꍇ
    CURSOR cur_get_head_line
    IS
      SELECT xshi.header_id              AS h_id        -- �w�b�_ID
            ,xshi.party_site_code        AS p_s_code    -- �o�א�
            ,xshi.shipping_instructions  AS ship_ins    -- �o�׎w��
            ,xshi.cust_po_number         AS c_po_num    -- �ڋq����
            ,xshi.order_source_ref       AS o_r_ref     -- �󒍃\�[�X�Q��
            ,xshi.schedule_ship_date     AS ship_date   -- �o�ח\���
            ,xshi.schedule_arrival_date  AS arr_date    -- ���ח\���
            ,xshi.location_code          AS lo_code     -- �o�׌�
            ,xshi.head_sales_branch      AS h_s_branch  -- �Ǌ����_
            ,xshi.data_type              AS data_type   -- �f�[�^�^�C�v
            ,xshi.arrival_time_from      AS arr_t_from  -- ���׎���From
            ,xshi.ordered_class          AS order_class -- �˗��敪
            ,xsli.orderd_item_code       AS ord_i_code  -- �󒍕i��
            ,xsli.orderd_quantity        AS ord_quant   -- ����
            ,xshi.input_sales_branch     AS in_sales_br -- ���͋��_
      FROM (SELECT xshi1.header_id
                  ,MAX (xshi1.last_update_date)
                   OVER (PARTITION BY xshi1.order_source_ref) max_date
            FROM  xxwsh_shipping_headers_if xshi1
           ) max_id
           ,xxwsh_shipping_headers_if  xshi -- �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j
           ,xxwsh_shipping_lines_if    xsli -- �o�׈˗��C���^�t�F�[�X���ׁi�A�h�I���j
      WHERE xshi.header_id          = max_id.header_id    -- �ŏI�X�V�����ő�̃w�b�_ID
      AND   xshi.last_update_date   = max_id.max_date     -- �ŏI�X�V��(�ő�)
      AND   xshi.data_type          = gv_10      -- [�o�׈˗�]��\���N�C�b�N�R�[�h�u�f�[�^�^�C�v�v
      AND   xshi.header_id          = xsli.header_id     -- �w�b�_ID
      AND   xshi.input_sales_branch = gr_param.in_base   -- ���͂o[���͋��_]
      ORDER BY xshi.order_source_ref -- �󒍃\�[�X�Q��
              ,xsli.line_id          -- ����ID
      ;
    -- ���͂o�u���͋��_�v�u�Ǌ����_�v�̗����Ƀf�[�^�����݂��Ă���ꍇ
    CURSOR cur_get_head_line_2
    IS
      SELECT xshi.header_id              AS h_id        -- �w�b�_ID
            ,xshi.party_site_code        AS p_s_code    -- �o�א�
            ,xshi.shipping_instructions  AS ship_ins    -- �o�׎w��
            ,xshi.cust_po_number         AS c_po_num    -- �ڋq����
            ,xshi.order_source_ref       AS o_r_ref     -- �󒍃\�[�X�Q��
            ,xshi.schedule_ship_date     AS ship_date   -- �o�ח\���
            ,xshi.schedule_arrival_date  AS arr_date    -- ���ח\���
            ,xshi.location_code          AS lo_code     -- �o�׌�
            ,xshi.head_sales_branch      AS h_s_branch  -- �Ǌ����_
            ,xshi.data_type              AS data_type   -- �f�[�^�^�C�v
            ,xshi.arrival_time_from      AS arr_t_from  -- ���׎���From
            ,xshi.ordered_class          AS order_class -- �˗��敪
            ,xsli.orderd_item_code       AS ord_i_code  -- �󒍕i��
            ,xsli.orderd_quantity        AS ord_quant   -- ����
            ,xshi.input_sales_branch     AS in_sales_br -- ���͋��_
      FROM (SELECT xshi1.header_id
                  ,MAX (xshi1.last_update_date)
                   OVER (PARTITION BY xshi1.order_source_ref) max_date
            FROM  xxwsh_shipping_headers_if xshi1
           ) max_id
           ,xxwsh_shipping_headers_if  xshi -- �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j
           ,xxwsh_shipping_lines_if    xsli -- �o�׈˗��C���^�t�F�[�X���ׁi�A�h�I���j
      WHERE xshi.header_id          = max_id.header_id    -- �ŏI�X�V��(�ő�)�̃w�b�_ID
      AND   xshi.last_update_date   = max_id.max_date     -- �ŏI�X�V��(�ő�)
      AND   xshi.data_type          = gv_10        -- [�o�׈˗�]��\���N�C�b�N�R�[�h�u�f�[�^�^�C�v�v
      AND   xshi.header_id          = xsli.header_id     -- �w�b�_ID
      AND   xshi.input_sales_branch = gr_param.in_base   -- ���͂o[���͋��_]
      AND   xshi.head_sales_branch  = gr_param.jur_base  -- ���͂o[�Ǌ����_]
      ORDER BY xshi.order_source_ref -- �󒍃\�[�X�Q��
              ,xsli.line_id          -- ����ID
      ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    --   �o�׈˗��C���^�t�F�[�X���𒊏o
    -- ====================================================
    -- �s���b�N�p�J�[�\���I�[�v��
    OPEN cur_get_lock;
    -- �s���b�N�p�J�[�\���N���[�Y
    CLOSE cur_get_lock;
--
    -- ���͂o[�Ǌ����_]��NULL�̏ꍇ
    IF (gr_param.jur_base IS NULL) THEN
      -- �J�[�\���I�[�v��
      OPEN cur_get_head_line;
      -- �o���N�t�F�b�`
      FETCH cur_get_head_line BULK COLLECT INTO ot_head_line;
      -- �J�[�\���N���[�Y
      CLOSE cur_get_head_line;
    ELSE
      -- �J�[�\���I�[�v��
      OPEN cur_get_head_line_2;
      -- �o���N�t�F�b�`
      FETCH cur_get_head_line_2 BULK COLLECT INTO ot_head_line;
      -- �J�[�\���N���[�Y
      CLOSE cur_get_head_line_2;
    END IF;
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_error_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_get_head_line%ISOPEN) THEN
        CLOSE cur_get_head_line;
      ELSIF (cur_get_head_line_2%ISOPEN) THEN
        CLOSE cur_get_head_line_2;
      END IF;
--
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_application   -- 'XXWSH'
                                                     ,gv_err_lock      -- ���b�N�G���[
                                                    )
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_get_head_line%ISOPEN) THEN
        CLOSE cur_get_head_line;
      ELSIF (cur_get_head_line_2%ISOPEN) THEN
        CLOSE cur_get_head_line_2;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_get_head_line%ISOPEN) THEN
        CLOSE cur_get_head_line;
      ELSIF (cur_get_head_line_2%ISOPEN) THEN
        CLOSE cur_get_head_line_2;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF (cur_get_head_line%ISOPEN) THEN
        CLOSE cur_get_head_line;
      ELSIF (cur_get_head_line_2%ISOPEN) THEN
        CLOSE cur_get_head_line_2;
      END IF;
--
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_get_head_line;
--
  /**********************************************************************************
   * Procedure Name   : pro_interface_chk
   * Description      : �C���^�[�t�F�C�X���`�F�b�N (B-4)
   ***********************************************************************************/
  PROCEDURE pro_interface_chk
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_interface_chk'; -- �v���O������
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
    ln_result          NUMBER;
    ln_in_base_cnt     NUMBER;    -- ���͋��_�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ---------------------------------------------------------------------------
    --  B-3�ɂĎ擾�������ځu�o�א�v�u�󒍃\�[�X�Q�Ɓv�u�o�ח\����v        --
    -- �u���ח\����v�u�o�׌��ۊǏꏊ�v�u�Ǌ����_�v�u�f�[�^�^�C�v�v�u�i�ځv  --
    -- �u���ʁv�ɒl���Z�b�g���Ă��邩�ǂ����̃`�F�b�N                        --
    ---------------------------------------------------------------------------
    -- �u�o�א�v�`�F�b�N NULL���A�G���[
    IF (gt_head_line(gn_i).p_s_code IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_1                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �u�󒍃\�[�X�Q�Ɓv�`�F�b�N NULL���A�G���[
    IF (gt_head_line(gn_i).o_r_ref IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_2                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �u�o�ח\����v�`�F�b�N NULL���A�G���[
    IF (gt_head_line(gn_i).ship_date IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_3                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �u���ח\����v�`�F�b�N NULL���A�G���[
    IF (gt_head_line(gn_i).arr_date IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_4                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �u�o�׌��ۊǏꏊ�v�`�F�b�N NULL���A�G���[
    IF (gt_head_line(gn_i).lo_code IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_5                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �u�Ǌ����_�v�`�F�b�N NULL���A�G���[
    IF (gt_head_line(gn_i).h_s_branch IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_6                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �u�f�[�^�^�C�v�v�`�F�b�N NULL���A�G���[
    IF (gt_head_line(gn_i).data_type IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_7                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �u�i�ځv�`�F�b�N NULL���A�G���[
    IF (gt_head_line(gn_i).ord_i_code IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_8                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �u���ʁv�`�F�b�N NULL���A�G���[
    IF (gt_head_line(gn_i).ord_quant IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_9                       --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    ---------------------------------------------------------------------------
    -- ���ʊ֐��u�˗�No�R���o�[�g�֐��v�ɂāA9���̈˗�No��12���˗�No�֕ϊ�
    ---------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.convert_request_number
                                  (
                                    gv_1                          -- in  '1'���_�����InBound�p
                                   ,gt_head_line(gn_i).o_r_ref    -- in  �󒍃\�[�X�Q�� �ύX�O�˗�No
                                   ,gv_new_order_no               -- out �ύX��
                                  );
--
    -- �o�׈˗��쐬����(�˗��m���P��)�p�J�E���g
    IF ((gn_i       = 1)
    OR  (gr_o_r_ref <> gt_head_line(gn_i).o_r_ref))
    THEN
      gn_req_cnt := gn_req_cnt + 1;
    END IF;
--
    --==========================================================================
    -- 1. �p�[�e�B�T�C�g�A�p�[�e�B�}�X�^�A�ڋq�}�X�^���u�o�א�v�̃`�F�b�N
    --==========================================================================
    BEGIN
--
      SELECT xpsv.party_site_id      -- �p�[�e�B�T�C�gID
            ,xpv.party_id            -- �ڋqID
            ,xpv.party_number        -- �g�D�ԍ�
            ,xpv.customer_class_code -- �ڋq�敪
            ,xpv.cust_enable_flag    -- ���~�q�\���t���O
      INTO   gr_p_site_id
            ,gr_c_acc_num
            ,gr_party_num
            ,gr_cus_c_code
            ,gr_cus_en_flag
      FROM   xxcmn_parties_v     xpv  -- �p�[�e�B���VIEW
            ,xxcmn_party_sites_v xpsv -- �p�[�e�B�T�C�g���VIEW
      WHERE xpv.party_id           = xpsv.party_id  -- �p�[�e�BID
      AND   xpsv.ship_to_no        = gt_head_line(gn_i).p_s_code
      ;
--
      -- �w���~�q�\���t���O�x���A�u0�v�ȊO�̏ꍇ�A���[�j���O
      IF (gr_cus_en_flag <> 0) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in ���   '�x��'
           ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
           ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => gv_msg_15                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST�̔���
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
    EXCEPTION
      -- �u�o�א�v���p�[�e�B�T�C�g�}�X�^�ɓo�^����Ă��Ȃ��ꍇ�A�G���[
      WHEN NO_DATA_FOUND THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in ���   '�G���['
           ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => gv_msg_10                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gt_head_line(gn_i).p_s_code    --  in �G���[����  �o�א�
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
    END;
--
    --==========================================================================
    -- 2. OPM�ۊǏꏊ�}�X�^���u�o�וۊǏꏊ�v�̃`�F�b�N
    --==========================================================================
    BEGIN
--
      SELECT xilv.inventory_location_id  -- �ۊǒIID
            ,xilv.allow_pickup_flag      -- �o�׈����Ώۃt���O
            ,xilv.frequent_mover         -- ��\�^�����
      INTO   gr_ship_id
            ,gr_a_p_flag
            ,gr_fre_mover
      FROM   xxcmn_item_locations_v   xilv    -- OPM�ۊǏꏊ���VIEW
      WHERE  xilv.segment1 = gt_head_line(gn_i).lo_code   -- �o�׌��ۊǏꏊ
      ;
--
      -- �u�o�׈����Ώۃt���O�v�������s�w0�x�A���[�j���O
      IF (gr_a_p_flag = gv_0) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in ���   '�x��'
           ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
           ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => gv_msg_43                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gt_head_line(gn_i).lo_code     --  in �G���[����  �o�׌��ۊǏꏊ
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST�̔���
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
    EXCEPTION
      -- �u�o�וۊǏꏊ�v��OPM�ۊǏꏊ�}�X�^�ɓo�^����Ă��Ȃ��ꍇ�A�G���[
      WHEN NO_DATA_FOUND THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in ���   '�G���['
           ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => gv_msg_11                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gt_head_line(gn_i).lo_code     --  in �G���[����  �o�׌��ۊǏꏊ
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
    END;
--
    --===========================================================================================
    -- 3. ��L2�Ńf�[�^�擾�ł��A����[��\�^�����]���ݒ肳��Ă���ꍇ�A[��\�^�����]�̎擾
    --===========================================================================================
    IF (gr_fre_mover IS NOT NULL) THEN
      SELECT xcv.party_number    -- �g�D�ԍ�
            ,xcv.party_id        -- �p�[�e�BID
      INTO   gr_party_number
            ,gr_party_id
      FROM   xxcmn_carriers_v  xcv  -- �^���Ǝҏ��VIEW
      WHERE  xcv.party_number = gr_fre_mover   -- ��\�^�����
      ;
    ELSE
      -- ���ݒ莞��NULL���Z�b�g
      gr_party_number := NULL;
      gr_party_id     := NULL;
    END IF;
--
    --==========================================================================
    -- 4. �p�[�e�B�}�X�^�E�ڋq�}�X�^�u�Ǌ����_�v
    --==========================================================================
    SELECT COUNT(xcav.account_number)
    INTO   ln_in_base_cnt
    FROM   xxcmn_cust_accounts_v  xcav  -- �ڋq��� V
    WHERE  xcav.account_number      = gt_head_line(gn_i).h_s_branch  -- �Ǌ����_
    AND    xcav.customer_class_code = gv_1                           -- '���_'�������u�R�[�h�敪�v
    AND    ROWNUM                   = 1
    ;
--
    -- �u�Ǌ����_�v���A�p�[�e�B�}�X�^�E�ڋq�}�X�^�ɑ��݂��Ȃ��ꍇ�A�G���[
    IF (ln_in_base_cnt = 0) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_12                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).h_s_branch  --  in �G���[���� �Ǌ����_
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- ����o�׈˗��w�b�_�̏ꍇ�́A1��݂̂̎擾�Ƃ���B
    IF ((gn_i    = 1)
    OR (gr_h_id <> gt_head_line(gn_i).h_id))
    THEN
      ----------------------------------------------------------------------------
      -- �u�i�ځv����w���i�敪�x�w�d�ʗe�ϋ敪�x�擾
      ----------------------------------------------------------------------------
      BEGIN
--
        SELECT xicv.prod_class_code           -- ���i�敪
              ,ximv.weight_capacity_class     -- �d�ʗe�ϋ敪
        INTO   gr_skbn
              ,gr_wei_kbn
        FROM   xxcmn_item_mst_v          ximv        -- OPM�i�ڏ��VIEW
              ,xxcmn_item_categories4_v  xicv        -- OPM�i�ڃJ�e�S���������VIEW4
        WHERE  ximv.item_id = xicv.item_id                   -- �i��ID
        AND    ximv.item_no = gt_head_line(gn_i).ord_i_code  -- �i��
        ;
--
      EXCEPTION
        -- �w���i�敪�x���擾�ł��Ȃ��ꍇ�A�G���[
        WHEN NO_DATA_FOUND THEN
          pro_err_list_make
            (
              iv_kind         => gv_msg_err                     --  in ���   '�G���['
             ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
             ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
             ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
             ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
             ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
             ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
             ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                                --  in �o�ɓ�
             ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                                --  in ����
             ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
             ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
             ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
             ,iv_err_msg      => gv_msg_13                      --  in �G���[���b�Z�[�W
             ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in �G���[����   �i��
             ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
             ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
             ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
            );
          -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
          gv_err_sts := gv_status_error;
--
          RAISE err_header_expt;
      END;
    END IF;
--
    -- ���ʊ֐��u�ő�z���敪�Z�o�֐��v�ɂāw�ő�z���敪�x�Z�o
    ln_result := xxwsh_common_pkg.get_max_ship_method
                           (
                             gv_4                         -- �R�[�h�敪1       in �q��'4'
                            ,gt_head_line(gn_i).lo_code   -- ���o�ɏꏊ�R�[�h1 in �o�׌��ۊǏꏊ
                            ,gv_9                         -- �R�[�h�敪2       in �z����'9'
                            ,gt_head_line(gn_i).p_s_code  -- ���o�ɏꏊ�R�[�h2 in �o�א�
                            ,gr_skbn                      -- ���i�敪          in ���i�敪
                            ,gr_wei_kbn                   -- �d�ʗe�ϋ敪      in �d�ʗe�ϋ敪
                            ,NULL                         -- �����z�ԑΏۋ敪  in NULL
                            ,gt_head_line(gn_i).ship_date -- ���            in �o�ח\���
                            ,gv_max_kbn                   -- �ő�z���敪     out �ő�z���敪
                            ,gn_drink_we                  -- �h�����N�ύڏd�� out �h�����N�ύڏd��
                            ,gn_leaf_we                   -- ���[�t�ύڏd��   out ���[�t�ύڏd��
                            ,gn_drink_ca                  -- �h�����N�ύڗe�� out �h�����N�ύڗe��
                            ,gn_leaf_ca                   -- ���[�t�ύڗe��   out ���[�t�ύڗe��
                            ,gn_prt_max                   -- �p���b�g�ő喇�� out �p���b�g�ő喇��
                           );
--
    -- �ő�z���敪�Z�o�֐�������ł͂Ȃ��ꍇ�A�G���[
    IF (ln_result = 1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_42                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST  �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -------------------------------------------------------------------------------
    -- �u�˗��敪�v����w�󒍃^�C�vID�x���擾
    -------------------------------------------------------------------------------
    BEGIN
--
      SELECT xettv.transaction_type_id           -- ����^�C�vID
      INTO   gr_odr_type
      FROM   xxcmn_lookup_values_v  xlvv            -- �N�C�b�N�R�[�h���View
            ,xxwsh_oe_transaction_types_v  xettv    -- �󒍃^�C�v���View
      WHERE  xlvv.lookup_type            = gv_shipping_class
      AND    xlvv.attribute2             = gt_head_line(gn_i).order_class  -- �˗��敪
      AND    xettv.order_category_code   = gv_order_c_code                 -- �󒍃J�e�S���R�[�h
      AND    xettv.transaction_type_name = xlvv.attribute5                 -- ����^�C�v
      ;
--
    EXCEPTION
      -- �w�󒍃^�C�vID�x���擾�ł��Ȃ��ꍇ�A�G���[
      WHEN NO_DATA_FOUND THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in ���   '�G���['
           ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => gv_msg_14                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gt_head_line(gn_i).order_class --  in �G���[����   '�˗��敪'
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST  �G���[�o�^
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
    END;
--
  EXCEPTION
    -- *** �G���[���b�Z�[�W�쐬�� ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
     ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_interface_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_day_time_chk
   * Description      : �ғ���/���[�h�^�C���`�F�b�N (B-5)
   ***********************************************************************************/
  PROCEDURE pro_day_time_chk
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_day_time_chk'; -- �v���O������
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
    ln_result    NUMBER;
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg_code  VARCHAR2(30);  -- �G���[�E���b�Z�[�W�E�R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -----------------------------------------------------------------------------------
    -- 1.���ʊ֐��u�ғ����Z�o�֐��v�ɂāw���ח\����x���ғ������ł��邩�`�F�b�N      --
    -----------------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.get_oprtn_day
                                (
                                  gt_head_line(gn_i).arr_date  -- ���t           in ���ח\���
                                 ,NULL                         -- �ۊǑq�ɃR�[�h in NULL
                                 ,gt_head_line(gn_i).p_s_code  -- �z����R�[�h   in �o�א�
                                 ,0                            -- ���[�h�^�C��   in 0
                                 ,gr_skbn                      -- ���i�敪       in ���i�敪
                                 ,gd_arr_work_day              -- �ғ������t    out �ғ���(����)
                                );
--
    -- �ғ����ł͂Ȃ��ꍇ�A���[�j���O
    IF (gd_arr_work_day IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_16                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in �G���[����  ���ח\���
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -----------------------------------------------------------------------------------
    -- 2.���ʊ֐��u�ғ����Z�o�֐��v�ɂāw�o�ח\����x���ғ������ł��邩�`�F�b�N      --
    -----------------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.get_oprtn_day
                                (
                                  gt_head_line(gn_i).ship_date -- ���t           in �o�ח\���
                                 ,gt_head_line(gn_i).lo_code   -- �ۊǑq�ɃR�[�h in �o�׌��ۊǏꏊ
                                 ,NULL                         -- �z����R�[�h   in NULL
                                 ,0                            -- ���[�h�^�C��   in 0
                                 ,gr_skbn                      -- ���i�敪       in ���i�敪
                                 ,gd_shi_work_day              -- �ғ������t    out �ғ���(�o��)
                                );
--
    -- �ғ����ł͂Ȃ��ꍇ�A���[�j���O
    IF (gd_shi_work_day IS NULL) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_17                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �G���[����  ���ח\���
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -----------------------------------------------------------------------------------------------
    -- 3.���ʊ֐��u���[�h�^�C���Z�o�v�ɂāw���Y�������[�h�^�C���x�w�z�����[�h�^�C���x�擾        --
    -----------------------------------------------------------------------------------------------
    xxwsh_common910_pkg.calc_lead_time
                                (
                                  gv_4                         -- �R�[�h�敪From   in �q��'4'
                                 ,gt_head_line(gn_i).lo_code   -- ���o�ɋ敪From   in �o�׌��ۊǏꏊ
                                 ,gv_9                         -- �R�[�h�敪To     in �z����'9'
                                 ,gt_head_line(gn_i).p_s_code  -- ���o�ɋ敪To     in �o�א�
                                 ,gr_skbn                      -- ���i�敪         in ���i�敪
                                 ,gr_odr_type                  -- �o�Ɍ`��ID       in �󒍃^�C�vID
                                 ,gt_head_line(gn_i).ship_date -- ���           in �o�ח\���
                                 ,lv_retcode                   -- ���^�[���E�R�[�h
                                 ,lv_errmsg_code               -- �G���[�E���b�Z�[�W�E�R�[�h
                                 ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
                                 ,gv_leadtime                  -- ���Y����LT/����ύXLT
                                 ,gv_delivery_lt               -- �z�����[�h�^�C��
                                );
--
    -- ���ʊ֐��G���[���A�G���[
    IF (lv_retcode = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => lv_errmsg                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_18                      --  in �G���[����
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    ------------------------------------------------------------------------------------
    -- 4.���ʊ֐��u�ғ����Z�o�֐��v�ɂĔz�����[�h�^�C���̓������A�ߋ��̉ғ����Z�o     --
    ------------------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.get_oprtn_day
                          (
                            gt_head_line(gn_i).arr_date  -- ���t           in ���ח\���
                           ,NULL                         -- �ۊǑq�ɃR�[�h in NULL
                           ,gt_head_line(gn_i).p_s_code  -- �z����R�[�h   in �o�א�
                           ,gv_delivery_lt               -- ���[�h�^�C��   in �z�����[�h�^�C��
                           ,gr_skbn                      -- ���i�敪       in ���i�敪
                           ,gd_de_past_day               -- �ғ������t    out �ғ������t(�ߋ��E�z��)
                          );
--
    ----------------------------------------------------------------------------
    -- 5.�ғ������t���o�ח\������ߋ����ǂ����̔���                         --
    ----------------------------------------------------------------------------
    IF (gt_head_line(gn_i).ship_date > gd_de_past_day) THEN
      -- �ߋ��̏ꍇ�A�z�����[�h�^�C���𖞂����Ă��Ȃ��ꍇ�A���[�j���O
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_19                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_delivery_lt                 --  in �G���[����  �z�����[�h�^�C��
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    --------------------------------------------------------------------------------------
    -- 6.���ʊ֐��u�ғ����Z�o�֐��v�ɂĐ��Y�������[�h�^�C���̓������w�ߋ��ғ����x�Z�o   --
    --------------------------------------------------------------------------------------
    ln_result := xxwsh_common_pkg.get_oprtn_day
                          (
                            gt_head_line(gn_i).ship_date  -- ���t           in �o�ח\���
                           ,NULL                          -- �ۊǑq�ɃR�[�h in NULL
                           ,gt_head_line(gn_i).p_s_code   -- �z����R�[�h   in �o�א�
                           ,gv_leadtime                   -- ���[�h�^�C��   in ���Y����LT/����ύXLT
                           ,gr_skbn                       -- ���i�敪       in ���i�敪
                           ,gd_past_day                   -- �ғ������t    out �ғ������t(�߁E���Y)
                           );
--
    ----------------------------------------------------------------------------
    -- 7.�ғ������t(����ύXLT�̉ߋ���)���V�X�e�����t���ߋ����ǂ����̔���   --
    ----------------------------------------------------------------------------
    IF (gd_sysdate > gd_past_day) THEN
      -- �ߋ��̏ꍇ�A���Y�������[�h�^�C���𖞂����Ă��Ȃ��B���[�j���O
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_20                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_leadtime                    --  in �G���[����  ���Y�������[�h�^�C��
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    ----------------------------------------------------------------------------
    -- 8.���ʊ֐��uOPM�݌ɉ�v���� CLOSE�N���擾�֐��v�ɂ�                    --
    --   �w�o�ח\����x�̉�v���Ԃ�Open����Ă��邩�`�F�b�N                   --
    ----------------------------------------------------------------------------
    -- �N���[�Y�̍ő�N���擾
    gv_opm_c_p := xxcmn_common_pkg.get_opminv_close_period;
--
    -- �o�ח\�����OPM�݌ɉ�v���ԂŃN���[�Y�̏ꍇ
    IF (gv_opm_c_p > TO_CHAR(gt_head_line(gn_i).ship_date,'YYYYMM')) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_21                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ship_date   --  in �G���[����  �o�ח\���
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_day_time_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_item_chk
   * Description      : ���׏��}�X�^���݃`�F�b�N (B-6)
   ***********************************************************************************/
  PROCEDURE pro_item_chk
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_item_chk'; -- �v���O������
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
    ln_amount    NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���ʂ��Z�b�g
    ln_amount := gt_head_line(gn_i).ord_quant;  -- ����
--
    SELECT ximv.inventory_item_id        -- �i��ID
          ,ximv.item_um                  -- �P��
          ,ximv.conv_unit                -- ���o�Ɋ��Z�P��
          ,ximv.num_of_cases             -- ����
          ,xicv.prod_class_code          -- ���i�敪
          ,xicv.item_class_code          -- �i�ڋ敪
--          ,CASE
--             WHEN ximv.conv_unit IS NULL     THEN ln_amount
--             WHEN ximv.conv_unit IS NOT NULL THEN (ln_amount * ximv.num_of_cases)
--           END    AS gn_item_amount      -- ����
          ,ln_amount                     -- ����
          ,ximv.max_palette_steps        -- �p���b�g����ő�i��
          ,ximv.delivery_qty             -- �z��
          ,ximv.weight_capacity_class    -- �d�ʗe�ϋ敪
          ,ximv.ship_class               -- �o�׋敪
          ,ximv.num_of_deliver           -- �o�ד���
          ,ximv.sales_div                -- ����Ώۋ敪
          ,ximv.obsolete_class           -- �p�~�敪
          ,ximv.rate_class               -- ���敪
    INTO   gr_i_item_id
          ,gr_item_um
          ,gr_conv_unit
          ,gr_case_am
          ,gr_item_skbn
          ,gr_item_kbn
          ,gn_item_amount
          ,gr_max_p_step
          ,gr_del_qty
          ,gr_i_wei_kbn
          ,gr_out_kbn
          ,gr_ship_am
          ,gr_sale_kbn
          ,gr_end_kbn
          ,gr_rit_kbn
    FROM  xxcmn_item_mst2_v         ximv     -- OPM�i�ڏ��VIEW
         ,xxcmn_item_categories4_v  xicv     -- OPM�i�ڃJ�e�S���������VIEW
    WHERE ximv.item_no            = gt_head_line(gn_i).ord_i_code -- �i��
    AND   ximv.item_id            = xicv.item_id                  -- �i��ID
    AND   ximv.start_date_active <= gd_sysdate
    AND   ximv.end_date_active   >= gd_sysdate
    ;
--
    -- �u�o�׋敪�v���w�ہx�̏ꍇ�B���[�j���O
    IF (gr_out_kbn = gv_0) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_23                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in �G���[����   �i��
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- �u����Ώۋ敪�v���u1�v�ȊO�̏ꍇ�B���[�j���O
    IF (gr_sale_kbn <> gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_24                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in �G���[����  �i��
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- �u�p�~�敪�v���uD�v�̏ꍇ�B���[�j���O
    IF (gr_end_kbn = gv_delete) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_25                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in �G���[����  �i��
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- �u���敪�v���u0�v�ȊO�̏ꍇ�B���[�j���O
    IF (gr_rit_kbn <> gv_0) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_26                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in �G���[����  �i��
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    --------------------------------------------------------------------
    -- ���i�敪�u�h�����N�v���i�ڋ敪�u���i�v�̏ꍇ�ŁA
    --�u�p���b�g����ő�i���v���w0�x�܂���NULL�A�G���[
    --------------------------------------------------------------------
    IF ((gr_item_skbn   = gv_2)
    AND (gr_item_kbn    = gv_5)
    AND ((gr_max_p_step IS NULL)
      OR (gr_max_p_step  = gv_0)))
    THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_27                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in �G���[����   �i��
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    --------------------------------------------------------------------
    -- ���i�敪�u�h�����N�v���i�ڋ敪�u���i�v�̏ꍇ�ŁA
    --�u�z���v���w0�x�܂���NULL�A�G���[
    --------------------------------------------------------------------
    IF ((gr_item_skbn  = gv_2)
    AND (gr_item_kbn   = gv_5)
    AND ((gr_del_qty   IS NULL)
      OR (gr_del_qty    = gv_0)))
    THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_28                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in �G���[����   �i��
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
  EXCEPTION
    -- �u�i�ځv��OPM�i�ڃ}�X�^�ɓo�^����Ă��Ȃ��ꍇ�A�G���[
    WHEN NO_DATA_FOUND THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_22                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ord_i_code  --  in �G���[����   �i��
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
      gv_err_flg := gv_2;
--
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_item_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_xsr_chk
   * Description      : �����\�����݃`�F�b�N (B-7)
   ***********************************************************************************/
  PROCEDURE pro_xsr_chk
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_xsr_chk'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_cnt      NUMBER;
    lv_yn_flg   VARCHAR2(1);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���݃`�F�b�N�t���O�A�J�E���g�ϐ�������
    ln_cnt    := 0;
    lv_yn_flg := gv_no;
--
    ----------------------------------------------------------------------------
    -- 1.�i��/�o�א�/�o�׌��ۊǏꏊ�ɂĕ����\���A�h�I���ւ̑��݃`�F�b�N       --
    ----------------------------------------------------------------------------
    SELECT COUNT (xsr.item_code)
    INTO   ln_cnt
    FROM   xxcmn_sourcing_rules  xsr   -- �����\���A�h�I���}�X�^ T
    WHERE  xsr.item_code          = gt_head_line(gn_i).ord_i_code
    AND    xsr.ship_to_code       = gt_head_line(gn_i).p_s_code
    AND    xsr.delivery_whse_code = gt_head_line(gn_i).lo_code
    AND    xsr.start_date_active <= gt_head_line(gn_i).ship_date
    AND    xsr.end_date_active   >= gt_head_line(gn_i).ship_date
    AND    ROWNUM                 = 1
    ;
--
    IF (ln_cnt = 1) THEN
      lv_yn_flg := gv_yes;
    END IF;
--
    ----------------------------------------------------------------------------
    -- 2.�i��/�Ǌ����_/�o�׌��ۊǏꏊ�ɂĕ����\���A�h�I���ւ̑��݃`�F�b�N     --
    ----------------------------------------------------------------------------
    -- ��L1�ɂ�0���̏ꍇ
    IF (lv_yn_flg = gv_no) THEN
      SELECT COUNT (xsr.item_code)
      INTO   ln_cnt
      FROM   xxcmn_sourcing_rules  xsr  -- �����\���A�h�I���}�X�^ T
      WHERE  xsr.item_code          = gt_head_line(gn_i).ord_i_code
      AND    xsr.base_code          = gt_head_line(gn_i).h_s_branch
      AND    xsr.delivery_whse_code = gt_head_line(gn_i).lo_code
      AND    xsr.start_date_active <= gt_head_line(gn_i).ship_date
      AND    xsr.end_date_active   >= gt_head_line(gn_i).ship_date
      AND    ROWNUM                 = 1
      ;
--
      IF (ln_cnt = 1) THEN
        lv_yn_flg := gv_yes;
      END IF;
    END IF;
--
    ----------------------------------------------------------------------------
    -- 3.�S�i��/�o�א�/�o�׌��ۊǏꏊ�ɂĕ����\���A�h�I���ւ̑��݃`�F�b�N     --
    ----------------------------------------------------------------------------
    -- ��L2�ɂ�0���̏ꍇ
    IF (lv_yn_flg = gv_no) THEN
      SELECT COUNT (xsr.item_code)
      INTO   ln_cnt
      FROM   xxcmn_sourcing_rules  xsr  -- �����\���A�h�I���}�X�^ T
      WHERE  xsr.item_code          = gv_all_item
      AND    xsr.ship_to_code       = gt_head_line(gn_i).p_s_code
      AND    xsr.delivery_whse_code = gt_head_line(gn_i).lo_code
      AND    xsr.start_date_active <= gt_head_line(gn_i).ship_date
      AND    xsr.end_date_active   >= gt_head_line(gn_i).ship_date
      AND    ROWNUM                 = 1
      ;
--
      IF (ln_cnt = 1) THEN
        lv_yn_flg := gv_yes;
      END IF;
    END IF;
--
    ----------------------------------------------------------------------------
    -- 4.�S�i��/�Ǌ����_/�o�׌��ۊǏꏊ�ɂĕ����\���A�h�I���ւ̑��݃`�F�b�N   --
    ----------------------------------------------------------------------------
    -- ��L3�ɂ�0���̏ꍇ
    IF (lv_yn_flg = gv_no) THEN
      SELECT COUNT (xsr.item_code)
      INTO   ln_cnt
      FROM   xxcmn_sourcing_rules  xsr  -- �����\���A�h�I���}�X�^ T
      WHERE  xsr.item_code          = gv_all_item
      AND    xsr.base_code          = gt_head_line(gn_i).h_s_branch
      AND    xsr.delivery_whse_code = gt_head_line(gn_i).lo_code
      AND    xsr.start_date_active <= gt_head_line(gn_i).ship_date
      AND    xsr.end_date_active   >= gt_head_line(gn_i).ship_date
      AND    ROWNUM                 = 1
      ;
--
      IF (ln_cnt = 1) THEN
        lv_yn_flg := gv_yes;
      END IF;
    END IF;
--
    -- ��L4�ɂ�0���̏ꍇ�B���[�j���O
    IF (lv_yn_flg = gv_no) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_29                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_xsr_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_total_we_ca
   * Description      : ���v�d��/���v�e�ώZ�o (B-8)
   ***********************************************************************************/
  PROCEDURE pro_total_we_ca
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_total_we_ca'; -- �v���O������
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
    lv_kougti      CONSTANT VARCHAR2(6)  := '%����%';
--
    -- *** ���[�J���ϐ� ***
    --ln_cnt         NUMBER;
    lv_errmsg_code VARCHAR2(30);  -- �G���[�E���b�Z�[�W�E�R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -----------------------------------------------------------------------------------
    -- ���ʊ֐��u�ύڌ����`�F�b�N(���v�l�Z�o)�v�ɂāw���v�d��/���v�e�ρx���Z�o       --
    -----------------------------------------------------------------------------------
    xxwsh_common910_pkg.calc_total_value
                            (
                              gt_head_line(gn_i).ord_i_code -- �i�ڃR�[�h   in �i��
                             ,gn_item_amount                -- ����         in ����
                             ,lv_retcode                    -- ���^�[���E�R�[�h
                             ,lv_errmsg_code                -- �G���[�E���b�Z�[�W�E�R�[�h
                             ,lv_errmsg                     -- �G���[�E���b�Z�[�W
                             ,gn_ttl_we                     -- ���v�d��         out ���v�d��
                             ,gn_ttl_ca                     -- ���v�e��         out ���v�e��
                             ,gn_ttl_prt_we                 -- ���v�p���b�g�d�� out ���v�p���b�g�d��
                            );
--
    -------------------------------------------------------------------------------
    -- ��ő�z���敪��ɕR�Â�������敪����Ώۂ��ǂ����`�F�b�N                    --
    -------------------------------------------------------------------------------
    SELECT COUNT (xlvv.meaning)
    INTO   gv_small_qty_flg
    FROM   xxcmn_lookup_values_v  xlvv  -- �N�C�b�N�R�[�h��� V
    WHERE  xlvv.lookup_type = gv_ship_method
    AND    xlvv.lookup_code = gv_max_kbn
    AND    xlvv.attribute6  = gv_1          -- �Ώ�
    AND    xlvv.meaning  LIKE lv_kougti;
--
    -- ����׏d�ʣ����חe�ϣ�Z�o
    --IF (gv_small_qty_flg = 1) THEN
      -- �w�Ώہx�ꍇ
      gn_detail_we := NVL(gn_ttl_we,0);                         -- ���׏d��
      gn_detail_ca := NVL(gn_ttl_ca,0);                         -- ���חe��
    --ELSE
      -- ��L�ȊO
      --gn_detail_we := NVL(gn_ttl_we,0) + NVL(gn_ttl_prt_we,0);  -- ���׏d��
      --gn_detail_ca := NVL(gn_ttl_ca,0) + NVL(gn_ttl_prt_we,0);  -- ���חe��
    --END IF;
--
    -- ���ʊ֐��ɂāA���^�[���R�[�h���G���[���B�G���[
    IF (lv_retcode = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => lv_errmsg                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => lv_errmsg                      --  in �G���[����
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_total_we_ca;
--
  /**********************************************************************************
   * Procedure Name   : pro_ship_y_n_chk
   * Description      : �o�׉ۃ`�F�b�N (B-9)
   ***********************************************************************************/
  PROCEDURE pro_ship_y_n_chk
    (
      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_ship_y_n_chk'; -- �v���O������
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
    ln_cnt      NUMBER;
    ln_result   NUMBER;
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg_code VARCHAR2(30);  -- �G���[�E���b�Z�[�W�E�R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --------------------------------
    -- 1.�v�揤�i�t���O�`�F�b�N   --
    --------------------------------
    -- ���݃`�F�b�N�t���O�A�J�E���g�ϐ�������
    ln_cnt    := 0;
--
    -- �����\���A�h�I������u�v�揤�i�t���O�v��ON�ł��邪�ǂ����̃`�F�b�N
    SELECT COUNT (xsr.item_code)
    INTO   ln_cnt
    FROM   xxcmn_sourcing_rules  xsr   -- �����\���A�h�I���}�X�^ T
    WHERE  xsr.item_code          = gt_head_line(gn_i).ord_i_code
    AND    xsr.base_code          = gt_head_line(gn_i).h_s_branch
    AND    xsr.delivery_whse_code = gt_head_line(gn_i).lo_code
    AND    xsr.start_date_active <= gt_head_line(gn_i).ship_date
    AND    xsr.end_date_active   >= gt_head_line(gn_i).ship_date
    AND    xsr.plan_item_flag     = gv_1
    AND    ROWNUM                 = 1
    ;
--
    --------------------------------
    -- 2.�o�׉ۃ`�F�b�N         --
    --------------------------------
    -- �o�א�����(���i��) �`�F�b�N
    xxwsh_common910_pkg.check_shipping_judgment
                          (
                            gv_2                           -- �`�F�b�N���@�敪 in �w2�x:���i��
                           ,gt_head_line(gn_i).h_s_branch  -- ���_             in �Ǌ����_
                           ,gr_i_item_id                   -- �i��ID           in �i��ID
                           ,gn_item_amount                 -- ����             in ����
                           ,gt_head_line(gn_i).arr_date    -- �Ώۓ�           in ���ח\���
                           ,gr_ship_id                     -- �o�׌�ID         in �o�׌�ID
                           ,gv_new_order_no                -- �˗�No           6/19�ǉ�
                           ,lv_retcode                     -- ���^�[���E�R�[�h
                           ,lv_errmsg_code                 -- �G���[�E���b�Z�[�W�E�R�[�h
                           ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
                           ,ln_result                      -- ��������
                          );
--
    -- �o�א�����(���i��) �o�׉ۃ`�F�b�N �ُ�I���̏ꍇ�A�G���[
    IF (lv_retcode = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => lv_errmsg                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => lv_errmsg_code                 --  in �G���[����
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �o�א�����(���i��)�`�F�b�N�ɂāu�������ʁv='1'(���ʃI�[�o�[�G���[)���A���[�j���O
    IF (ln_result = 1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_31                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in �G���[����  ����
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- �o�א�����(������) �`�F�b�N
    xxwsh_common910_pkg.check_shipping_judgment
                          (
                            gv_3                           -- �`�F�b�N���@�敪 in �w3�x:������
                           ,gt_head_line(gn_i).h_s_branch  -- ���_             in �Ǌ����_
                           ,gr_i_item_id                   -- �i��ID           in �i��ID
                           ,gn_item_amount                 -- ����             in ����
                           ,gt_head_line(gn_i).ship_date   -- �Ώۓ�           in �o�ח\���
                           ,gr_ship_id                     -- �o�׌�ID         in �o�׌�ID
                           ,gv_new_order_no                -- �˗�No           6/19�ǉ�
                           ,lv_retcode                     -- ���^�[���E�R�[�h
                           ,lv_errmsg_code                 -- �G���[�E���b�Z�[�W�E�R�[�h
                           ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
                           ,ln_result                      -- ��������
                          );
--
    -- �o�א�����(������) �o�׉ۃ`�F�b�N �ُ�I���̏ꍇ�A�G���[
    IF (lv_retcode = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => lv_errmsg                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => lv_errmsg_code                 --  in �G���[����
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �o�א�����(������)�`�F�b�N�ɂāu�������ʁv='1'(���ʃI�[�o�[�G���[)���A���[�j���O
    IF (ln_result = 1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_32                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in �G���[����  ����
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- �o�א�����(������)�`�F�b�N�ɂāu�������ʁv='2'(�o�ג�~���G���[)���A���[�j���O
    IF (ln_result = 2) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_33                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ship_date   --  in �G���[����  �o�ח\���
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- ���i�敪���u���[�t�v�̏ꍇ�A����v��`�F�b�N���{
    IF (gr_skbn = gv_1) THEN
      xxwsh_common910_pkg.check_shipping_judgment
                            (
                              gv_1                           -- �`�F�b�N���@�敪 in �w1�x
                             ,gt_head_line(gn_i).h_s_branch  -- ���_             in �Ǌ����_
                             ,gr_i_item_id                   -- �i��ID           in �i��ID
                             ,gn_item_amount                 -- ����             in ����
                             ,gt_head_line(gn_i).arr_date    -- �Ώۓ�           in ���ח\���
                             ,gr_ship_id                     -- �o�׌�ID         in �o�׌�ID
                             ,gv_new_order_no                -- �˗�No           6/19�ǉ�
                             ,lv_retcode                     -- ���^�[���E�R�[�h
                             ,lv_errmsg_code                 -- �G���[�E���b�Z�[�W�E�R�[�h
                             ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
                             ,ln_result                      -- ��������
                            );
--
      -- ����v��`�F�b�N �ُ�I���̏ꍇ�A�G���[
      IF (lv_retcode = gv_1) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in ���   '�G���['
           ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => lv_errmsg                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => lv_errmsg_code                 --  in �G���[����
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
      END IF;
      -- �u�������ʁv='1'(���ʃI�[�o�[�G���[)���A���[�j���O
      IF (ln_result = 1) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in ���   '�x��'
           ,iv_dec          => gv_msg_war                     --  in �m��   '�x��'
           ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => gv_msg_30                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in �G���[����  ����
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST�̔���
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
    END IF;
--
    -- �v�揤�i�t���O��ON�̏ꍇ�A�v�揤�i�`�F�b�N
    IF (ln_cnt = 1) THEN
      xxwsh_common910_pkg.check_shipping_judgment
                            (
                              gv_4                           -- �`�F�b�N���@�敪 in �w4�x:�v�揤�i
                             ,gt_head_line(gn_i).h_s_branch  -- ���_             in �Ǌ����_
                             ,gr_i_item_id                   -- �i��ID           in �i��ID
                             ,gn_item_amount                 -- ����             in ����
                             ,gt_head_line(gn_i).ship_date   -- �Ώۓ�           in �o�ח\���
                             ,gr_ship_id                     -- �o�׌�ID         in �o�׌�ID
                             ,gv_new_order_no                -- �˗�No           6/19�ǉ�
                             ,lv_retcode                     -- ���^�[���E�R�[�h
                             ,lv_errmsg_code                 -- �G���[�E���b�Z�[�W�E�R�[�h
                             ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
                             ,ln_result                      -- ��������
                            );
--
      -- �v�揤�i����v��`�F�b�N �ُ�I���̏ꍇ�A�G���[
      IF (lv_retcode = gv_1) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in ���   '�G���['
           ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => lv_errmsg                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => lv_errmsg_code                 --  in �G���[����
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
        gv_err_sts := gv_status_error;
--
        RAISE err_header_expt;
      END IF;
      -- �u�������ʁv='1'(���ʃI�[�o�[�G���[)���A���[�j���O
      IF (ln_result = 1) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in ���   '�x��'
           ,iv_dec          => gv_msg_war                     --  in �m��   '�x��'
           ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => gv_msg_34                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in �G���[����  ����
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST�̔���
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_2;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_ship_y_n_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_lines_create
   * Description      : �󒍖��׃A�h�I�����R�[�h���� (B-10)
   ***********************************************************************************/
  PROCEDURE pro_lines_create
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_lines_create'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    ln_mod_chk      NUMBER DEFAULT 0;      -- �����{�`�F�b�N
    lv_dsc          VARCHAR2(6);           -- �G���[���b�Z�[�W���e����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���הԍ��̍̔ԁA�w�b�_���ڗp���v��������
    IF ((gr_h_id    = gt_head_line(gn_i).h_id)
    AND (gr_o_r_ref = gt_head_line(gn_i).o_r_ref))
    THEN
      -- ���הԍ��J�E���g�{�P
      gn_line_number := gn_line_number + 1;
    -- ���񃌃R�[�h�����A[�w�b�_ID][�󒍃\�[�X�Q��]���O�f�[�^�ƈقȂ�ꍇ
    ELSE
      -- ���הԍ���[1]�Z�b�g
      gn_line_number := 1;
      -- �w�b�_���ڗp���v��������
      gn_ttl_ship_am  := 0;  -- �o�גP�ʊ��Z��
      gn_h_ttl_weight := 0;  -- �ύڏd�ʍ��v
      gn_h_ttl_capa   := 0;  -- �ύڗe�ύ��v
      gn_h_ttl_pallet := 0;  -- ���v�p���b�g�d��
      gn_pallet_t_c_am  := 0;  -- �p���b�g���v����
    END IF;
--
    ------------------------------------------------------
    -- 1.�u�p���b�g���v�u�i���v�u�P�[�X���v�Z�o         --
    ------------------------------------------------------
    -- �e�l�̏�����
    gn_p_max_case_am  := 0;  -- �p���b�g����ő�P�[�X��
    gn_case_total     := 0;  -- �P�[�X�����v
    gn_pallet_am      := 0;  -- �p���b�g��
    gn_step_am        := 0;  -- �i��
    gn_case_am        := 0;  -- �P�[�X��
    gn_pallet_co_am   := 0;  -- �p���b�g����
--
    -- (1).�e�l�̍œK��
    -- �u�p���b�g����ő�P�[�X���v= �z�� * �p���b�g����ő�i��
    gn_p_max_case_am := gr_del_qty * gr_max_p_step;
--
    -- �u�P�[�X�����v0���Z����
    IF (gr_case_am = 0) THEN
      gn_case_total := 0;                -- �P�[�X�����v
    ELSE
      -- �u�P�[�X�����v�v= B-3�̐��� / �P�[�X���� [�����_�ȉ��؎̂�]
      gn_case_total := TRUNC(gt_head_line(gn_i).ord_quant / gr_case_am);
    END IF;
--
    -- �u�p���b�g����ő�P�[�X���v0���Z����
    IF (gn_p_max_case_am = 0) THEN
      gn_pallet_am  := 0;                -- �p���b�g��
    ELSE
      -- �u�p���b�g���v= �P�[�X�����v / �p���b�g����ő�P�[�X�� [�����_�ȉ��؎̂�]
      gn_pallet_am  := TRUNC(gn_case_total / gn_p_max_case_am);
    END IF;
--
    -- �u�z���v0���Z����
    IF (TO_NUMBER(gr_del_qty) = 0) THEN
      gn_step_am    := 0;                -- �i��
      gn_case_am    := 0;                -- �P�[�X��
    ELSE
      -- �u�i���v= ((�P�[�X�����v / �p���b�g����ő�P�[�X��)�̏�]) / �z�� [�����_�ȉ��؎̂�]
      gn_step_am := TRUNC(MOD(gn_case_total,gn_p_max_case_am) / TO_NUMBER(gr_del_qty));
      -- �u�P�[�X���v= (((�P�[�X�����v / �p���b�g����ő�P�[�X��)�̏�]) / �z��)�̏�]
      gn_case_am := MOD(MOD(gn_case_total,gn_p_max_case_am),TO_NUMBER(gr_del_qty));
    END IF;
--
    -- (2).�p���b�g�����̎Z�o
    -- �u�i���v���́u�P�[�X���v��0�ȏ�̏ꍇ
    IF ((gn_step_am > 0)
    OR  (gn_case_am > 0))
    THEN
      gn_pallet_co_am := gn_pallet_am + 1;
    ELSE
      gn_pallet_co_am := gn_pallet_am;
    END IF;
--
    -- (3).�p���b�g���v�����̎Z�o
    gn_pallet_t_c_am  := gn_pallet_t_c_am + gn_pallet_co_am;
--
--
    -- ����ʣ����z����̐����{�ł͂Ȃ��ꍇ�B���[�j���O
    ln_mod_chk := MOD(gn_item_amount,TO_NUMBER(gr_del_qty));
    IF (ln_mod_chk <> 0) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in ���   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_35                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����  '-'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    ------------------------------------------------------
    -- 2.�󒍖��׃A�h�I���쐬�p���R�[�h�ϐ��֊i�[       --
    ------------------------------------------------------
    ord_l_all.order_line_id              := gn_lines_seq;                  -- �󒍖��׃A�h�I��ID
    ord_l_all.order_header_id            := gn_headers_seq;                -- �󒍃w�b�_�A�h�I��ID
    ord_l_all.order_line_number          := gn_line_number;                -- ���הԍ�
    ord_l_all.request_no                 := gv_new_order_no;               -- �˗�No
    ord_l_all.shipping_inventory_item_id := gr_i_item_id;                  -- �o�וi��ID
    ord_l_all.shipping_item_code         := gt_head_line(gn_i).ord_i_code; -- �o�וi��
    ord_l_all.quantity                   := gn_item_amount;                -- ����
    ord_l_all.uom_code                   := gr_item_um;                    -- �P��
    ord_l_all.based_request_quantity     := gt_head_line(gn_i).ord_quant;  -- ���_�˗�����
    ord_l_all.weight                     := NVL(gn_detail_we,0);           -- �d��
    ord_l_all.capacity                   := NVL(gn_detail_ca,0);           -- �e��
    ord_l_all.pallet_weight              := NVL(gn_ttl_prt_we,0);          -- �p���b�g�d��
    ord_l_all.request_item_id            := gr_i_item_id;                  -- �˗��i��ID
    ord_l_all.request_item_code          := gt_head_line(gn_i).ord_i_code; -- �˗��i��
    ord_l_all.pallet_quantity            := gn_pallet_am;                  -- �p���b�g��
    ord_l_all.layer_quantity             := gn_step_am;                    -- �i��
    ord_l_all.case_quantity              := gn_case_am;                    -- �P�[�X��
    ord_l_all.pallet_qty                 := gn_pallet_co_am;               -- �p���b�g����
    ord_l_all.delete_flag                := gv_no;                         -- �폜�t���O
    ord_l_all.shipping_request_if_flg    := gv_no;
    ord_l_all.shipping_result_if_flg     := gv_no;
    ord_l_all.created_by                 := gn_created_by;                 -- �쐬��
    ord_l_all.creation_date              := gd_creation_date;              -- �쐬��
    ord_l_all.last_updated_by            := gn_last_upd_by;                -- �ŏI�X�V��
    ord_l_all.last_update_date           := gd_last_upd_date;              -- �ŏI�X�V��
    ord_l_all.last_update_login          := gn_last_upd_login;             -- �ŏI�X�V���O�C��
    ord_l_all.request_id                 := gn_request_id;                 -- �v��ID
    ord_l_all.program_application_id     := gn_prog_appl_id;               -- �v���O�����A�v��ID
    ord_l_all.program_id                 := gn_prog_id;                    -- �v���O����ID
    ord_l_all.program_update_date        := gd_prog_upd_date;              -- �v���O�����X�V��
    gv_wei_kbn                           := gr_i_wei_kbn;                  -- �d�ʗe�ϋ敪
--
    -- �o�׈˗��쐬���׌���(�˗����גP��) �J�E���g
    gn_line_cnt := gn_line_cnt + 1;
--
    ------------------------------------------------------
    -- 3.�o�גP�ʊ��Z���̎Z�o                           --
    ------------------------------------------------------
    -- (1).��o�ד�������ݒ肳��Ă���ꍇ�A�u���ʁv/�u�o�ד����v(�����_�ȉ��l�̌ܓ�)
    IF (gr_ship_am IS NOT NULL) THEN
      -- 0���Z����
      IF (gr_ship_am = 0) THEN
        gn_ship_amount := 0;
      ELSE
        gn_ship_amount := ROUND(gn_item_amount / gr_ship_am,0);
      END IF;
--
      -- ����ʣ����o�ד�����̐����{�ł͂Ȃ��ꍇ�A���[�j���O
      ln_mod_chk := MOD(gn_item_amount,gr_ship_am);
      IF (ln_mod_chk <> 0) THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in ���   '�x��'
           ,iv_dec          => gv_msg_err                     --  in ���   '�G���['
           ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => gv_msg_36                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����  '-'
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST�̔���
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
    -- (2).(1)�ȊO�A���������ݒ肳��Ă���ꍇ�A�u���ʁv/�u�����v(�����_�ȉ��l�̌ܓ�)
    ELSIF (gr_case_am IS NOT NULL) THEN
      -- 0���Z����
      IF (gr_case_am = 0) THEN
        gn_ship_amount := 0;
      ELSE
        gn_ship_amount := ROUND(gn_item_amount / gr_case_am,0);
      END IF;
--
      -- ����ʣ���������̐����{�ł͂Ȃ��ꍇ�B���[�j���O
      ln_mod_chk := MOD(gn_item_amount,gr_case_am);
      IF (ln_mod_chk <> 0) THEN
        -- ���o�Ɋ��Z�P�ʂ̔���
        IF (gr_conv_unit IS NOT NULL) THEN
          -- ���o�Ɋ��Z�P�ʂ��ݒ肳��Ă���ꍇ�A�m�荀�� '�G���['
          lv_dsc := gv_msg_err;
        ELSE
          -- ���o�Ɋ��Z�P�ʂ����ݒ�̏ꍇ�A�m�荀�� '�|'
          lv_dsc := gv_msg_hfn;
        END IF;
--
        pro_err_list_make
          (
            iv_kind         => gv_msg_war                     --  in ���   '�x��'
           ,iv_dec          => lv_dsc                         --  in �m��
           ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => gv_msg_37                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����  '-'
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST�̔���
        IF (gv_err_sts <> gv_status_error) THEN
          gv_err_sts := gv_status_warn;
        END IF;
      END IF;
--
    -- (3).(2)�ȊO�A�u���ʁv�ݒ�
    ELSE
      gn_ship_amount := gn_item_amount;
    END IF;
--
    -- �󒍃w�b�_�A�h�I�����ڗp�ϐ� ���Z
    gn_ttl_ship_am  := gn_ttl_ship_am  + gn_ship_amount;             -- �o�גP�ʊ��Z��
    gn_h_ttl_weight := gn_h_ttl_weight + NVL(gn_ttl_we,0);           -- �ύڏd�ʍ��v
    gn_h_ttl_capa   := gn_h_ttl_capa   + NVL(gn_ttl_ca,0);           -- �ύڗe�ύ��v
    gn_h_ttl_pallet := gn_h_ttl_pallet + NVL(gn_ttl_prt_we,0);       -- ���v�p���b�g�d��
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_lines_create;
--
  /**********************************************************************************
   * Procedure Name   : pro_load_eff_chk
   * Description      : �ύڌ����`�F�b�N (B-11)
   ***********************************************************************************/
  PROCEDURE pro_load_eff_chk
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_load_eff_chk'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_errmsg_code VARCHAR2(30);  -- �G���[�E���b�Z�[�W�E�R�[�h
    --
    ln_h_ttl_weight NUMBER;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �u�p���b�g�ő喇���v�Ɓu�p���b�g���v�����v�̔�r
    --  �o�ו��@(�A�h�I��)�̃p���b�g�ő喇���𒴂����ꍇ�G���[�Ƃ���
    IF (gn_prt_max < gn_pallet_t_c_am) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in ���   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_38                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gn_pallet_t_c_am               --  in �G���[����  �p���b�g���v����
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    --
    IF ( gv_small_qty_flg = 0 ) THEN
      ln_h_ttl_weight :=  gn_h_ttl_weight + gn_h_ttl_pallet;
    ELSE
      ln_h_ttl_weight := gn_h_ttl_weight;
    END IF;
    --
    -- ���ʊ֐���ύڌ����`�F�b�N(�ύڌ����Z�o)��ɂă`�F�b�N (���׏d�ʂ̏ꍇ)
    xxwsh_common910_pkg.calc_load_efficiency
                            (
                              ln_h_ttl_weight              -- ���v�d��         in �ύڏd�ʍ��v
                             ,NULL                         -- ���v�e��         in NULL
                             ,gv_4                         -- �R�[�h�敪From   in �q��'4'
                             ,gt_head_line(gn_i).lo_code   -- ���o�ɋ敪From   in �o�׌��ۊǏꏊ
                             ,gv_9                         -- �R�[�h�敪To     in �z����'9'
                             ,gt_head_line(gn_i).p_s_code  -- ���o�ɋ敪To     in �o�א�
                             ,gv_max_kbn                   -- �ő�z���敪     in �ő�z���敪
                             ,gr_item_skbn                 -- ���i�敪         in ���i�敪
                             ,NULL                         -- �����z�ԑΏۋ敪 in NULL
                             ,gt_head_line(gn_i).ship_date -- ���           in �o�ח\���
                             ,lv_retcode                   -- ���^�[���E�R�[�h
                             ,lv_errmsg_code               -- �G���[�E���b�Z�[�W�E�R�[�h
                             ,lv_errmsg                    -- �G���[�E���b�Z�[�W
                             ,gv_over_kbn                  -- �ύڃI�[�o�[�敪 0:����,1:�I�[�o�[
                             ,gv_ship_way                  -- �o�ו��@
                             ,gn_we_loading                -- �d�ʐύڌ���
                             ,gn_ca_dammy                  -- �e�ϐύڌ���
                             ,gv_mix_ship                  -- ���ڔz���敪
                            );
--
    -- ���^�[���R�[�h���G���[���B�G���[
    IF (lv_retcode = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => lv_errmsg                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => lv_errmsg                      --  in �G���[����   �i��
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �ύڃI�[�o�[���A���[�j���O
    IF (gv_over_kbn = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_39                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in �G���[����   ����
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
    -- ���ʊ֐���ύڌ����`�F�b�N(�ύڌ����Z�o)��ɂă`�F�b�N (���חe�ς̏ꍇ)
    xxwsh_common910_pkg.calc_load_efficiency
                            (
                              NULL                         -- ���v�d��         in NULL
                             ,gn_h_ttl_capa                -- ���v�e��         in �ύڗe�ύ��v
                             ,gv_4                         -- �R�[�h�敪From   in �q��'4'
                             ,gt_head_line(gn_i).lo_code   -- ���o�ɋ敪From   in �o�׌��ۊǏꏊ
                             ,gv_9                         -- �R�[�h�敪To     in �z����'9'
                             ,gt_head_line(gn_i).p_s_code  -- ���o�ɋ敪To     in �o�א�
                             ,gv_max_kbn                   -- �ő�z���敪     in �ő�z���敪
                             ,gr_item_skbn                 -- ���i�敪         in ���i�敪
                             ,NULL                         -- �����z�ԑΏۋ敪 in NULL
                             ,gt_head_line(gn_i).ship_date -- ���           in �o�ח\���
                             ,lv_retcode                   -- ���^�[���E�R�[�h
                             ,lv_errmsg_code               -- �G���[�E���b�Z�[�W�E�R�[�h
                             ,lv_errmsg                    -- �G���[�E���b�Z�[�W
                             ,gv_over_kbn                  -- �ύڃI�[�o�[�敪 0:����,1:�I�[�o�[
                             ,gv_ship_way                  -- �o�ו��@
                             ,gn_we_dammy                  -- �d�ʐύڌ���
                             ,gn_ca_loading                -- �e�ϐύڌ���
                             ,gv_mix_ship                  -- ���ڔz���敪
                            );
--
    -- ���^�[���R�[�h���G���[���B�G���[
    IF (lv_retcode = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => lv_errmsg                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => lv_errmsg                      --  in �G���[����   �i��
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
--
    -- �ύڃI�[�o�[���A���[�j���O
    IF (gv_over_kbn = gv_1) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_war                     --  in ���   '�x��'
         ,iv_dec          => gv_msg_err                     --  in �m��   '�G���['
         ,iv_req_no       => gv_new_order_no                --  in �˗�No(12��)
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_39                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gt_head_line(gn_i).ord_quant   --  in �G���[����   ����
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST�̔���
      IF (gv_err_sts <> gv_status_error) THEN
        gv_err_sts := gv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_load_eff_chk;
--
  /**********************************************************************************
   * Procedure Name   : pro_headers_create
   * Description      : �󒍃w�b�_�A�h�I�����R�[�h���� (B-12)
   ***********************************************************************************/
  PROCEDURE pro_headers_create
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_headers_create'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���v���ʂ̎Z�o
    IF (gr_h_id = gt_head_line(gn_i).h_id) THEN
      -- ����w�b�_ID�̏ꍇ�A���ׂ̐��ʂ����Z
      gn_ttl_amount := gn_ttl_amount + gn_item_amount;
    ELSE
      gn_ttl_amount := gn_item_amount;
    END IF;
--
    -- ��{�d�ʁE��{�e�ϔ���
    -- ���i�敪�u���[�t�v�̏ꍇ
    IF (gr_item_skbn = gv_1) THEN
      gn_basic_we := gn_leaf_we;
      gn_basic_ca := gn_leaf_ca;
    -- ���i�敪�u�h�����N�v�̏ꍇ
    ELSIF (gr_item_skbn = gv_2) THEN
      gn_basic_we := gn_drink_we;
      gn_basic_ca := gn_drink_ca;
    END IF;
--
    ------------------------------------------------------
    -- �󒍃w�b�_�A�h�I���쐬�p���R�[�h�ϐ��֊i�[       --
    ------------------------------------------------------
    ord_h_all.order_header_id              := gn_headers_seq;                -- �󒍃w�b�_�A�h�I��ID
    ord_h_all.order_type_id                := gr_odr_type;                     -- �󒍃^�C�vID
    ord_h_all.organization_id              := gv_name_m_org;                   -- �g�DID
    ord_h_all.latest_external_flag         := gv_yes;                          -- �ŐV�t���O
    ord_h_all.ordered_date                 := gd_sysdate;                      -- �󒍓�
    ord_h_all.customer_id                  := gr_c_acc_num;                    -- �ڋqID
    ord_h_all.customer_code                := gr_party_num;                    -- �ڋq
    ord_h_all.deliver_to_id                := gr_p_site_id;                    -- �o�א�ID
    ord_h_all.deliver_to                   := gt_head_line(gn_i).p_s_code;     -- �o�א�
    ord_h_all.shipping_instructions        := gt_head_line(gn_i).ship_ins;     -- �o�׎w��
    ord_h_all.career_id                    := gr_party_id;                     -- �^���Ǝ�ID
    ord_h_all.freight_carrier_code         := gr_party_number;                 -- �^���Ǝ�
    ord_h_all.shipping_method_code         := gv_max_kbn;                      -- �z���敪
    ord_h_all.cust_po_number               := gt_head_line(gn_i).c_po_num;     -- �ڋq����
    ord_h_all.request_no                   := gv_new_order_no;                 -- �˗�No
    ord_h_all.req_status                   := gr_ship_st;                      -- �X�e�[�^�X
    ord_h_all.schedule_ship_date           := gt_head_line(gn_i).ship_date;    -- �o�ח\���
    ord_h_all.schedule_arrival_date        := gt_head_line(gn_i).arr_date;     -- ���ח\���
    ord_h_all.confirm_request_class        := gv_0;                            -- �����S���m�F�˗��敪
    ord_h_all.freight_charge_class         := gv_1;                            -- �^���敪
    ord_h_all.no_cont_freight_class        := gv_0;                            -- �_��O�^���敪
    ord_h_all.deliver_from_id              := gr_ship_id;                      -- �o�׌�ID
    ord_h_all.deliver_from                 := gt_head_line(gn_i).lo_code;      -- �o�׌��ۊǏꏊ
    ord_h_all.Head_sales_branch            := gt_head_line(gn_i).h_s_branch;   -- �Ǌ����_
    ord_h_all.input_sales_branch           := gt_head_line(gn_i).in_sales_br;  -- ���͋��_
    ord_h_all.prod_class                   := gr_skbn;                         -- ���i�敪
    ord_h_all.arrival_time_from            := gt_head_line(gn_i).arr_t_from;   -- ���׎���FROM
    ord_h_all.sum_quantity                 := gn_ttl_amount;                   -- ���v����
    ord_h_all.small_quantity               := gn_ttl_ship_am;                  -- ������
    ord_h_all.label_quantity               := gn_ttl_ship_am;                  -- ���x������
    ord_h_all.loading_efficiency_weight    := gn_we_loading;                   -- �d�ʐύڌ���
    ord_h_all.loading_efficiency_capacity  := gn_ca_loading;                   -- �e�ϐύڌ���
    ord_h_all.based_weight                 := gn_basic_we;                     -- ��{�d��
    ord_h_all.based_capacity               := gn_basic_ca;                     -- ��{�e��
    ord_h_all.sum_weight                   := gn_h_ttl_weight;                 -- �ύڏd�ʍ��v
    ord_h_all.sum_capacity                 := gn_h_ttl_capa;                   -- �ύڗe�ύ��v
    ord_h_all.sum_pallet_weight            := gn_h_ttl_pallet;                 -- ���v�p���b�g�d��
    ord_h_all.pallet_sum_quantity          := gn_pallet_t_c_am;                -- �p���b�g���v����
    ord_h_all.order_source_ref             := NULL;                            -- �󒍃\�[�X�Q��
    ord_h_all.weight_capacity_class        := gr_wei_kbn;                      -- �d�ʗe�ϋ敪
    ord_h_all.actual_confirm_class         := gv_no;                           -- ���ьv��ϋ敪
    ord_h_all.notif_status                 := gr_notice_st;                    -- �ʒm�X�e�[�^�X
    ord_h_all.new_modify_flg               := gv_no;                           -- �V�K�C���t���O
    ord_h_all.performance_management_dept  := NULL;                            -- ���ъǗ�����
    ord_h_all.created_by                   := gn_created_by;                   -- �쐬��
    ord_h_all.creation_date                := gd_creation_date;                -- �쐬��
    ord_h_all.last_updated_by              := gn_last_upd_by;                  -- �ŏI�X�V��
    ord_h_all.last_update_date             := gd_last_upd_date;                -- �ŏI�X�V��
    ord_h_all.last_update_login            := gn_last_upd_login;               -- �ŏI�X�V���O�C��
    ord_h_all.request_id                   := gn_request_id;                   -- �v��ID
    ord_h_all.program_application_id       := gn_prog_appl_id;                 -- �v���O�����A�v��ID
    ord_h_all.program_id                   := gn_prog_id;                      -- �v���O����ID
    ord_h_all.program_update_date          := gd_prog_upd_date;                -- �v���O�����X�V��
--
    -- �d�ʗe�ϋ敪�̃`�F�b�N
    IF (gr_wei_kbn <> gv_wei_kbn) THEN
      pro_err_list_make
        (
          iv_kind         => gv_msg_err                     --  in ���   '�G���['
         ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
         ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
         ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
         ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
         ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
         ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
         ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                            --  in �o�ɓ�
         ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                            --  in ����
         ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
         ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
         ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
         ,iv_err_msg      => gv_msg_40                      --  in �G���[���b�Z�[�W
         ,iv_err_clm      => gv_msg_hfn                     --  in �G���[����   '�|'
         ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
         ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
         ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
        );
      -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
      gv_err_sts := gv_status_error;
--
      RAISE err_header_expt;
    END IF;
  EXCEPTION
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_headers_create;
--
  /**********************************************************************************
   * Procedure Name   : pro_order_ins_del
   * Description      : �󒍃A�h�I���o��  (B-13)
   ***********************************************************************************/
  PROCEDURE pro_order_ins_del
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_order_ins_del'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    ln_chk      NUMBER DEFAULT 0;      -- �󒍃w�b�_�A�h�I�����݃`�F�b�N
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ----------------------------------------------------------------------------
    -- 1.�󒍃w�b�_�A�h�I���̓o�^�󋵁^�X�e�[�^�X�`�F�b�N
    ----------------------------------------------------------------------------
    SELECT COUNT (xoha.order_header_id)    -- �󒍃w�b�_�A�h�I��ID
    INTO   ln_chk
    FROM   xxwsh_order_headers_all   xoha   -- �󒍃w�b�_�A�h�I��
    WHERE  xoha.request_no = gv_new_order_no  -- �˗�No
    AND    ROWNUM          = 1
    ;
--
    -- �󒍃w�b�_�A�h�I���ɑ��݂��Ă���ꍇ
    IF (ln_chk = 1) THEN
      SELECT xoha.order_header_id    -- �󒍃w�b�_�A�h�I��ID
            ,xoha.req_status         -- �X�e�[�^�X
      INTO   gr_ord_he_id
            ,gr_req_status
      FROM   xxwsh_order_headers_all   xoha   -- �󒍃w�b�_�A�h�I��
      WHERE  xoha.request_no           = gv_new_order_no  -- �˗�No
      AND    xoha.latest_external_flag = gv_yes           -- �ŐV�t���O'Y'
      ;
--
      -- ��L�ɂĎ擾�����f�[�^�̃X�e�[�^�X�����_�m��ȏ�̏ꍇ�A�G���[
      --IF ((gr_req_status > gv_01)
      --AND (gr_req_status < gv_99))
      IF (gr_req_status <> gv_01)
      THEN
        pro_err_list_make
          (
            iv_kind         => gv_msg_err                     --  in ���   '�G���['
           ,iv_dec          => gv_msg_hfn                     --  in �m��   '�|'
           ,iv_req_no       => gt_head_line(gn_i).o_r_ref     --  in �˗�No
           ,iv_kyoten       => gt_head_line(gn_i).h_s_branch  --  in �Ǌ����_
           ,iv_ship_to      => gt_head_line(gn_i).p_s_code    --  in �o�א�
           ,iv_description  => gt_head_line(gn_i).ship_ins    --  in �E�v
           ,iv_cust_pono    => gt_head_line(gn_i).c_po_num    --  in �ڋq�����ԍ�
           ,iv_ship_date    => TO_CHAR(gt_head_line(gn_i).ship_date,'YYYY/MM/DD')
                                                              --  in �o�ɓ�
           ,iv_arrival_date => TO_CHAR(gt_head_line(gn_i).arr_date,'YYYY/MM/DD')
                                                              --  in ����
           ,iv_ship_from    => gt_head_line(gn_i).lo_code     --  in �o�׌�
           ,iv_item         => gt_head_line(gn_i).ord_i_code  --  in �i��
           ,in_qty          => gt_head_line(gn_i).ord_quant   --  in ����
           ,iv_err_msg      => gv_msg_41                      --  in �G���[���b�Z�[�W
           ,iv_err_clm      => gn_pallet_t_c_am               --  in �G���[����  �p���b�g���v����
           ,ov_errbuf       => lv_errbuf                      -- out �G���[�E���b�Z�[�W
           ,ov_retcode      => lv_retcode                     -- out ���^�[���E�R�[�h
           ,ov_errmsg       => lv_errmsg                      -- out ���[�U�[�E�G���[�E���b�Z�[�W
          );
        -- ���ʃG���[���b�Z�[�W �I��ST �G���[�o�^
        gv_err_sts := gv_status_error;
--
        -- IF�e�[�u���폜�Ώ�
        gv_del_if_flg := gv_yes;
--
        RAISE err_header_expt;
      END IF;
--
      ----------------------------------------------------------------------------
      -- 2.�f�[�^�폜����                                                       --
      ----------------------------------------------------------------------------
      -- �o�^�Ώہu�˗�No�v�̃X�e�[�^�X���w���͒��x�̏ꍇ�A�󒍃w�b�_�A�h�I��/�󒍖��׃A�h�I���폜
      IF (((gr_h_id      <> gt_head_line(gn_i).h_id) OR ( gr_h_id IS NULL ))
      AND (gr_req_status = gr_ship_st))
      THEN
        -- �󒍖��׃A�h�I���폜
        DELETE
        FROM   xxwsh_order_lines_all   xola    -- �󒍖��׃A�h�I��
        WHERE  xola.order_header_id    = gr_ord_he_id   -- �󒍃w�b�_�A�h�I��ID
        ;
      END IF;
--
      IF (gr_req_status = gr_ship_st) THEN
        -- �󒍃w�b�_�A�h�I���폜
        DELETE
        FROM   xxwsh_order_headers_all xoha    -- �󒍃w�b�_�A�h�I��
        WHERE  xoha.order_header_id    = gr_ord_he_id   -- �󒍃w�b�_�A�h�I��ID
        ;
--
      END IF;
    END IF;
--
--
    ----------------------------------------------------------------------------
    -- 3.�󒍃w�b�_�A�h�I���E�󒍖��׃A�h�I���փf�[�^�o�^                     --
    ----------------------------------------------------------------------------
    -- *************************************************
    -- ***  �󒍃w�b�_�A�h�I���e�[�u���o�^           ***
    -- *************************************************
    INSERT INTO xxwsh_order_headers_all
      ( order_header_id
       ,order_type_id
       ,organization_id
       ,latest_external_flag
       ,ordered_date
       ,customer_id
       ,customer_code
       ,deliver_to_id
       ,deliver_to
       ,shipping_instructions
       ,career_id
       ,freight_carrier_code
       ,shipping_method_code
       ,cust_po_number
       ,request_no
       ,req_status
       ,schedule_ship_date
       ,schedule_arrival_date
       ,confirm_request_class
       ,freight_charge_class
       ,no_cont_freight_class
       ,deliver_from_id
       ,deliver_from
       ,head_sales_branch
       ,input_sales_branch
       ,prod_class
       ,arrival_time_from
       ,sum_quantity
       ,small_quantity
       ,label_quantity
       ,loading_efficiency_weight
       ,loading_efficiency_capacity
       ,based_weight
       ,based_capacity
       ,sum_weight
       ,sum_capacity
       ,sum_pallet_weight
       ,pallet_sum_quantity
       ,order_source_ref
       ,weight_capacity_class
       ,actual_confirm_class
       ,notif_status
       ,new_modify_flg
       ,performance_management_dept
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
      ) VALUES
      ( ord_h_all.order_header_id
       ,ord_h_all.order_type_id
       ,ord_h_all.organization_id
       ,ord_h_all.latest_external_flag
       ,ord_h_all.ordered_date
       ,ord_h_all.customer_id
       ,ord_h_all.customer_code
       ,ord_h_all.deliver_to_id
       ,ord_h_all.deliver_to
       ,ord_h_all.shipping_instructions
       ,ord_h_all.career_id
       ,ord_h_all.freight_carrier_code
       ,ord_h_all.shipping_method_code
       ,ord_h_all.cust_po_number
       ,ord_h_all.request_no
       ,ord_h_all.req_status
       ,ord_h_all.schedule_ship_date
       ,ord_h_all.schedule_arrival_date
       ,ord_h_all.confirm_request_class
       ,ord_h_all.freight_charge_class
       ,ord_h_all.no_cont_freight_class
       ,ord_h_all.deliver_from_id
       ,ord_h_all.deliver_from
       ,ord_h_all.Head_sales_branch
       ,ord_h_all.input_sales_branch
       ,ord_h_all.prod_class
       ,ord_h_all.arrival_time_from
       ,ord_h_all.sum_quantity
       ,ord_h_all.small_quantity
       ,ord_h_all.label_quantity
       ,ord_h_all.loading_efficiency_weight
       ,ord_h_all.loading_efficiency_capacity
       ,ord_h_all.based_weight
       ,ord_h_all.based_capacity
       ,ord_h_all.sum_weight
       ,ord_h_all.sum_capacity
       ,ord_h_all.sum_pallet_weight
       ,ord_h_all.pallet_sum_quantity
       ,ord_h_all.order_source_ref
       ,ord_h_all.weight_capacity_class
       ,ord_h_all.actual_confirm_class
       ,ord_h_all.notif_status
       ,ord_h_all.new_modify_flg
       ,ord_h_all.performance_management_dept
       ,ord_h_all.created_by
       ,ord_h_all.creation_date
       ,ord_h_all.last_updated_by
       ,ord_h_all.last_update_date
       ,ord_h_all.last_update_login
       ,ord_h_all.request_id
       ,ord_h_all.program_application_id
       ,ord_h_all.program_id
       ,ord_h_all.program_update_date
      );
--
    -- *************************************************
    -- ***  �󒍖��׃A�h�I���e�[�u���o�^             ***
    -- *************************************************
    INSERT INTO xxwsh_order_lines_all
      ( order_line_id
       ,order_header_id
       ,order_line_number
       ,request_no
       ,shipping_inventory_item_id
       ,shipping_item_code
       ,quantity
       ,uom_code
       ,based_request_quantity
       ,weight
       ,capacity
       ,pallet_weight
       ,request_item_id
       ,request_item_code
       ,pallet_quantity
       ,layer_quantity
       ,case_quantity
       ,pallet_qty
       ,delete_flag
       ,shipping_request_if_flg
       ,shipping_result_if_flg
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
       ,request_id
       ,program_application_id
       ,program_id
       ,program_update_date
      ) VALUES
      ( ord_l_all.order_line_id
       ,ord_l_all.order_header_id
       ,ord_l_all.order_line_number
       ,ord_l_all.request_no
       ,ord_l_all.shipping_inventory_item_id
       ,ord_l_all.shipping_item_code
       ,ord_l_all.quantity
       ,ord_l_all.uom_code
       ,ord_l_all.based_request_quantity
       ,ord_l_all.weight
       ,ord_l_all.capacity
       ,ord_l_all.pallet_weight
       ,ord_l_all.request_item_id
       ,ord_l_all.request_item_code
       ,ord_l_all.pallet_quantity
       ,ord_l_all.layer_quantity
       ,ord_l_all.case_quantity
       ,ord_l_all.pallet_qty
       ,ord_l_all.delete_flag
       ,ord_l_all.shipping_request_if_flg
       ,ord_l_all.shipping_result_if_flg
       ,ord_l_all.created_by
       ,ord_l_all.creation_date
       ,ord_l_all.last_updated_by
       ,ord_l_all.last_update_date
       ,ord_l_all.last_update_login
       ,ord_l_all.request_id
       ,ord_l_all.program_application_id
       ,ord_l_all.program_id
       ,ord_l_all.program_update_date
      );
--
  EXCEPTION
    -- *** ���ʊ֐� �x���E�G���[ ***
    WHEN err_header_expt THEN
      gv_err_flg := gv_1;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_order_ins_del;
--
  /**********************************************************************************
   * Procedure Name   : pro_purge_del
   * Description      : �p�[�W����   (B-14)
   ***********************************************************************************/
  PROCEDURE pro_purge_del
    (
      ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pro_purge_del'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���̓p�����[�^�u���͋��_�v�̂ݐݒ�̏ꍇ
    IF (gr_param.jur_base IS NULL) THEN
      -- �o�׈˗��C���^�t�F�[�X���ׁi�A�h�I���j�Ώۃf�[�^�폜
      DELETE
      FROM  xxwsh_shipping_lines_if    xsli -- �o�׈˗��C���^�t�F�[�X���ׁi�A�h�I���j
      WHERE xsli.header_id IN
        (SELECT xshi.header_id
         FROM   xxwsh_shipping_headers_if  xshi -- �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j
         WHERE  xshi.header_id          = xshi.header_id     -- �w�b�_ID
         AND    xshi.input_sales_branch = gr_param.in_base   -- ���͋��_
         AND    xshi.data_type          = gv_10     -- [�o�׈˗�]�������N�C�b�N�R�[�h(�f�[�^�^�C�v)
        )
      ;
--
      -- �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j�Ώۃf�[�^�폜
      DELETE
      FROM   xxwsh_shipping_headers_if  xshi -- �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j
      WHERE  xshi.header_id          = xshi.header_id     -- �w�b�_ID
      AND    xshi.input_sales_branch = gr_param.in_base   -- ���͋��_
      AND    xshi.data_type          = gv_10     -- [�o�׈˗�]�������N�C�b�N�R�[�h(�f�[�^�^�C�v)
      ;
--
    -- ���̓p�����[�^�u���͋��_�v�u�Ǌ����_�v�����ݒ�̏ꍇ
    ELSE
      -- �o�׈˗��C���^�t�F�[�X���ׁi�A�h�I���j�Ώۃf�[�^�폜
      DELETE
      FROM  xxwsh_shipping_lines_if    xsli -- �o�׈˗��C���^�t�F�[�X���ׁi�A�h�I���j
      WHERE xsli.header_id IN
        (SELECT xshi.header_id
         FROM   xxwsh_shipping_headers_if  xshi -- �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j
         WHERE  xshi.header_id          = xshi.header_id     -- �w�b�_ID
         AND    xshi.input_sales_branch = gr_param.in_base   -- ���͋��_
         AND    xshi.head_sales_branch  = gr_param.jur_base  -- �Ǌ����_
         AND    xshi.data_type          = gv_10     -- [�o�׈˗�]�������N�C�b�N�R�[�h(�f�[�^�^�C�v)
        )
      ;
--
      -- �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j�Ώۃf�[�^�폜
      DELETE
      FROM   xxwsh_shipping_headers_if  xshi -- �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j
      WHERE  xshi.header_id          = xshi.header_id     -- �w�b�_ID
      AND    xshi.input_sales_branch = gr_param.in_base   -- ���͋��_
      AND    xshi.head_sales_branch  = gr_param.jur_base  -- �Ǌ����_
      AND    xshi.data_type          = gv_10     -- [�o�׈˗�]�������N�C�b�N�R�[�h(�f�[�^�^�C�v)
      ;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END pro_purge_del;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_in_base    IN  VARCHAR2    --  01.���͋��_
     ,iv_jur_base   IN  VARCHAR2    --  02.�Ǌ����_
     ,ov_errbuf     OUT VARCHAR2    --  �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2    --  ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2    --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
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
    ln_j       NUMBER;          -- �J�E���^�ϐ�(����)
    ln_k       NUMBER;          -- �J�E���^�ϐ�(�w�b�_)
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- -----------------------------------------------------
    -- �p�����[�^�i�[
    -- -----------------------------------------------------
    gr_param.in_base   := iv_in_base;     -- ���͋��_
    gr_param.jur_base  := iv_jur_base;    -- �Ǌ����_
--
    -- �J�n���̃V�X�e�����ݓ��t����
    gd_sysdate         := TRUNC( SYSDATE );
--
    -- ���ʃG���[���b�Z�[�W �I��ST������
    gv_err_sts         := gv_status_normal;
--
    -- =====================================================
    --  �֘A�f�[�^�擾 (B-1)
    -- =====================================================
    pro_get_cus_option
      (
        ov_errbuf         => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ���̓p�����[�^�`�F�b�N    (B-2)
    -- =====================================================
    pro_param_chk
      (
        ov_errbuf         => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �o�׈˗��C���^�[�t�F�[�X���擾   (B-3)
    -- =====================================================
    pro_get_head_line
      (
        ot_head_line    => gt_head_line     -- �擾���R�[�h�Q
       ,ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    <<headers_data_loop>>
    FOR i IN 1..gt_head_line.COUNT LOOP
      -- LOOP�J�E���g�p�ϐ��փJ�E���g���}��
      gn_i := i;
--
      -- �G���[�m�F�p�t���O������
      gv_err_flg := gv_0;
--
      -- ���񃌃R�[�h�����w�b�_ID���قȂ����ꍇ�A���s
      IF ((gn_i     = 1)
      OR  (gr_h_id <> gt_head_line(gn_i).h_id))
      THEN
        ---------------------------------------------
        -- �󒍃w�b�_�A�h�I��ID �V�[�P���X�擾     --
        ---------------------------------------------
        SELECT xxwsh_order_headers_all_s1.NEXTVAL
        INTO   gn_headers_seq
        FROM   dual
        ;
--
        -- �o�׈˗��C���^�[�t�F�C�X�w�b�_�����J�E���g
        gn_sh_h_cnt := gn_sh_h_cnt + 1;
--
      END IF;
--
      -- =====================================================
      --  �C���^�[�t�F�C�X���`�F�b�N   (B-4)
      -- =====================================================
      pro_interface_chk
        (
          ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �G���[�m�F�p�t���O (B-4�ɂăG���[�̏ꍇ�́A���L�������{���Ȃ�)
     IF (gv_err_flg <> gv_1) THEN
        -- =====================================================
        --  �ғ���/���[�h�^�C���`�F�b�N   (B-5)
        -- =====================================================
        pro_day_time_chk
          (
            ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- �G���[�m�F�p�t���O (B-5�ɂăG���[�̏ꍇ�́A���L�������{���Ȃ�)
      IF (gv_err_flg <> gv_1) THEN
        ---------------------------------------------
        -- �󒍖��׃A�h�I��ID �V�[�P���X�擾       --
        ---------------------------------------------
        SELECT xxwsh_order_lines_all_s1.NEXTVAL
        INTO   gn_lines_seq
        FROM   dual;
--
        -- =====================================================
        --  ���׏��}�X�^���݃`�F�b�N (B-6)
        -- =====================================================
        pro_item_chk
          (
            ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �G���[�m�F�p�t���O (B-6�ɂăG���[�̏ꍇ�́A���L�������{���Ȃ�)
        IF (gv_err_flg <> gv_2) THEN
          -- =====================================================
          --  �����\�����݃`�F�b�N (B-7)
          -- =====================================================
          pro_xsr_chk
            (
              ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- �G���[�m�F�p�t���O (B-7�ɂăG���[�̏ꍇ�́A���L�������{���Ȃ�)
        IF (gv_err_flg <> gv_2) THEN
          -- =====================================================
          --  ���v�d��/���v�e�ώZ�o (B-8)
          -- =====================================================
          pro_total_we_ca
            (
              ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- �G���[�m�F�p�t���O (B-8�ɂăG���[�̏ꍇ�́A���L�������{���Ȃ�)
        IF (gv_err_flg <> gv_2) THEN
          -- =====================================================
          --  �o�׉ۃ`�F�b�N (B-9)
          -- =====================================================
          pro_ship_y_n_chk
            (
              ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- =====================================================
        --  �󒍖��׃A�h�I�����R�[�h���� (B-10)
        -- =====================================================
        pro_lines_create
          (
            ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �G���[�m�F�p�t���O�߂�
        IF (gv_err_flg = gv_2) THEN
          gv_err_flg := gv_0;
        END IF;
      END IF;
--
      -- �G���[�m�F�p�t���O (B-5�ɂăG���[�̏ꍇ�́A���L�������{���Ȃ�)
      IF (gv_err_flg <> gv_1) THEN
        -- =====================================================
        --  �ύڌ����`�F�b�N (B-11)
        -- =====================================================
        pro_load_eff_chk
          (
            ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- �G���[�m�F�p�t���O (B-11�܂łŃG���[�̏ꍇ�́A���L�������{���Ȃ�)
      IF (gv_err_flg <> gv_1) THEN
        -- =====================================================
        --  �󒍃w�b�_�A�h�I�����R�[�h���� (B-12)
        -- =====================================================
        pro_headers_create
          (
            ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        --  �󒍃A�h�I���o��  (B-13)
        -- =====================================================
        pro_order_ins_del
          (
            ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- �w�b�_ID�A�󒍃\�[�X�Q�Ɣ���p���ڍX�V
      gr_h_id    := gt_head_line(gn_i).h_id;
      gr_o_r_ref := gt_head_line(gn_i).o_r_ref;
--
      -- �擾�����f�[�^�̃X�e�[�^�X�����_�m��ȏ�̏ꍇ�A�w�b�_ID��ێ�����B
      IF (gv_del_if_flg = gv_yes) THEN
        gt_del_if(gn_i) := gt_head_line(gn_i).h_id;
      END IF;
--
      -- IF�e�[�u���폜�Ώۃt���O��������
      gv_del_if_flg := NULL;
--
    END LOOP headers_data_loop;
--
    -- �X�e�[�^�X��}��
    IF (gt_head_line.COUNT = 0) THEN
      ov_retcode := gv_status_normal;
    ELSIF ((gv_err_sts = gv_status_warn)
    OR     (gv_err_sts = gv_status_error))
    THEN
      ov_retcode := gv_err_sts;
    END IF;
--
    -- �X�e�[�^�X���G���[�̏ꍇ�͏������{���Ȃ�
    IF (ov_retcode <> gv_status_error) THEN
      -- =====================================================
      --  �p�[�W����   (B-14)
      -- =====================================================
      pro_purge_del
        (
          ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �擾�����f�[�^�̃X�e�[�^�X�����_�m��ȏ�̃��R�[�h��IF�����������B
    IF (gt_del_if.COUNT > 0) THEN
      FORALL ln_j IN 1 .. gt_del_if.COUNT
        DELETE xxwsh_shipping_lines_if    xsli -- �o�׈˗��C���^�t�F�[�X���ׁi�A�h�I���j
        WHERE  xsli.header_id = gt_del_if(ln_j);
--
      FORALL ln_k IN 1 .. gt_del_if.COUNT
        DELETE xxwsh_shipping_headers_if  xshi -- �o�׈˗��C���^�t�F�[�X�w�b�_�i�A�h�I���j
        WHERE  xshi.header_id = gt_del_if(ln_k);
--
      COMMIT;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
  PROCEDURE main
    (
      errbuf        OUT VARCHAR2      --  �G���[�E���b�Z�[�W  --# �Œ� #
     ,retcode       OUT VARCHAR2      --  ���^�[���E�R�[�h    --# �Œ� #
     ,iv_in_base    IN  VARCHAR2      --  01.���͋��_
     ,iv_jur_base   IN  VARCHAR2      --  02.�Ǌ����_
    )
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
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain
      (
        iv_in_base   => iv_in_base   --  01.���͋��_
       ,iv_jur_base  => iv_jur_base  --  02.�Ǌ����_
       ,ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    -----------------------------------------------
    -- ���̓p�����[�^�o��                        --
    -----------------------------------------------
    -- ���̓p�����[�^�u���͋��_�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11057','IN_KYOTEN',gr_param.in_base);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- ���̓p�����[�^�u�Ǌ����_�v�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-11008','KYOTEN',gr_param.jur_base);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �G���[���X�g�o��
    IF (gt_err_msg.COUNT > 0) THEN
      -- ���ږ��o��
      gv_err_report := gv_name_kind      || CHR(9) || gv_name_dec       || CHR(9) ||
                       gv_name_req_no    || CHR(9) || gv_tkn_msg_ju_b   || CHR(9) ||
                       gv_name_ship_to   || CHR(9) || gv_name_descrip   || CHR(9) ||
                       gv_name_cust_pono || CHR(9) || gv_name_ship_date || CHR(9) ||
                       gv_name_arr_date  || CHR(9) || gv_name_ship_from || CHR(9) ||
                       gv_name_item_a    || CHR(9) || gv_name_qty       || CHR(9) ||
                       gv_name_err_msg   || CHR(9) || gv_name_err_clm;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- ���ڋ�؂���o��
      gv_err_report := gv_line || gv_line || gv_line || gv_line || gv_line || gv_line || gv_line;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- �G���[���X�g���e�o��
      <<err_report_loop>>
      FOR i IN 1..gt_err_msg.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gt_err_msg(i).err_msg);
      END LOOP err_report_loop;
--
      --��؂蕶����o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      ELSIF (lv_errbuf IS NULL) THEN
        --���[�U�[�E�G���[�E���b�Z�[�W�̃R�s�[
        lv_errbuf := lv_errmsg;
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      --��؂蕶����o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    END IF;
--
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --���������o��(�o�׈˗��C���^�[�t�F�C�X�w�b�_����)
    gv_out_msg := xxcmn_common_pkg.get_msg( 'XXWSH'
                                           ,'APP-XXWSH-11058'
                                           ,'CNT'
                                           ,TO_CHAR(gn_sh_h_cnt)
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��(�o�׈˗��C���^�[�t�F�C�X���׌���)
    gv_out_msg := xxcmn_common_pkg.get_msg( 'XXWSH'
                                           ,'APP-XXWSH-11059'
                                           ,'CNT'
                                           ,TO_CHAR(gt_head_line.COUNT)
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��(�o�׈˗��쐬����(�˗��m���P��))
    gv_out_msg := xxcmn_common_pkg.get_msg( 'XXWSH'
                                           ,'APP-XXWSH-11010'
                                           ,'CNT'
                                           ,TO_CHAR(gn_req_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��(�o�׈˗��쐬����(�˗����גP��))
    gv_out_msg := xxcmn_common_pkg.get_msg( 'XXWSH'
                                           ,'APP-XXWSH-11011'
                                           ,'CNT'
                                           ,TO_CHAR(gn_line_cnt)
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh400002c;
/