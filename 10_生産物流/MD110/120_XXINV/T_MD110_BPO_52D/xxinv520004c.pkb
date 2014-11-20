CREATE OR REPLACE PACKAGE BODY xxinv520004c
AS
/*****************************************************************************
* �p�b�P�[�W���Fxxinv520004c
* �@�\�T�v�@�@�F�H���}�X�^�o�^(�i�ڐU�֗\��)
* �o�[�W�����@�F1.0
* �쐬�ҁ@�@�@�F��r ���
* �쐬���@�@�@�F2008/11/17
* �ύX�ҁ@�@�@�F
* �ŏI�ύX���@�F
* �C�����e�@�@�F
* 
*****************************************************************************/
--
  --==========================================================================
  --  �O���[�o���萔
  --==========================================================================
  gv_status_normal        CONSTANT VARCHAR2(1)    := '0';    --����
  gv_status_warn          CONSTANT VARCHAR2(1)    := '1';    --�x��
  gv_status_error         CONSTANT VARCHAR2(1)    := '2';    --���s
  gv_pkg_name             CONSTANT VARCHAR2(30)   := 'xxinv520004c';
--
  gv_fml_sts_new          CONSTANT VARCHAR2(4)    := '100';  -- �V�K
  gv_fml_sts_appr         CONSTANT VARCHAR2(4)    := '700';  -- ��ʎg�p�̏��F
--
  gv_msg_kbn_inv          CONSTANT VARCHAR2(5)    := 'XXINV';
-- ���b�Z�[�W�ԍ�
  gv_msg_52a_00           CONSTANT VARCHAR2(15)   := 'APP-XXINV-10000'; -- API�G���[
  gv_tkn_api_name         CONSTANT VARCHAR2(15)   := 'API_NAME';
--
  gv_tkn_upd_routing      CONSTANT VARCHAR2(20)   := '�H���X�V';
--
  --==========================================================================
  --  �O���[�o���ϐ�
  --==========================================================================
  gn_total_cnt            NUMBER  := 0;
--
  gv_proc_name            VARCHAR2(100);
--
  --==========================================================================
  --  �O���[�o����O
  --==========================================================================
  sub_func_expt    EXCEPTION;
  oprn_id_err      EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt  EXCEPTION;
--
  /***************************************************************************
  * PUROCEDURE���Fsubmain
  * �@�\�T�v�@�@�F�H���}�X�^�o�^�������C��
  * �����@�@�@�@�F
  *               OUT  ov_ret_status               ���^�[���E�X�e�[�^�X
  *               OUT  ov_err_msg                  �G���[�E���b�Z�[�W
  * ���ӎ����@�@�F
  ***************************************************************************/
  PROCEDURE submain(
    ov_ret_status  OUT VARCHAR2
  , ov_err_msg     OUT VARCHAR2
  )
  IS
--
    --========================================================================
    --  ���[�J���ϐ�
    --========================================================================
    lv_ret_status                VARCHAR2(1)   ;     --  ���^�[���E�X�e�[�^�X
    -- INSERT_FORMULA API�p�ϐ�
    lv_return_status             VARCHAR2(2)   ;
    ln_message_count             NUMBER        ;
    lv_msg_date                  VARCHAR2(2000);
    -- MODIFY_STATUS API�p�ϐ�
    lv_msg_list                  VARCHAR2(2000);
    --********************
    -- �H���}�X�^���
    --********************
    lt_routing_no                gmd_routings_b.routing_no%TYPE;              -- �H��No
    lt_routings_step_tab         gmd_routings_pub.gmd_routings_step_tab;      -- �H���z��
    lt_routings_step_dep_tab     gmd_routings_pub.gmd_routings_step_dep_tab;  -- �_�~�[�H���z��
    routings_b_rec               gmd_routings%rowtype;                        -- �H���f�[�^�i�[�p
    ln_oprn_id                   gmd_operations_b.oprn_id%type;               -- �H��ID�i�[�p
--
    --========================================================================
    --  �G���[����
    --========================================================================
    lv_err_msg                   VARCHAR2(2000);  --  �G���[�E���b�Z�[�W
--
    --========================================================================
    --  �ۊǏꏊ���̒��o
    --========================================================================
    CURSOR  locations_cur
    IS
      SELECT xilv.segment1  location        -- �[�i�ꏊ
           , xilv.whse_code whse_code       -- �[�i�q��
      FROM   xxcmn_item_locations_v xilv
      WHERE  NOT EXISTS (SELECT 1
                         FROM   gmd_routings_b x
                         WHERE  x.routing_no = '9' || xilv.segment1 )
      ORDER BY xilv.segment1
      ;
--
    --========================================================================
    --  �H��ID�擾
    --========================================================================
    CURSOR lc_oprn_id
    IS
      SELECT oprn_id
      FROM   gmd_operations_b gob
      WHERE  gob.oprn_no = '900' -- �i�ڐU��
      ;
--
  BEGIN
    --========================================================================
    --  OUT�p�����[�^�̏�����
    --========================================================================
    ov_ret_status :=  gv_status_normal;
    ov_err_msg    :=  NULL;
--
    --========================================================================
    --  �H��ID�擾
    --========================================================================
    OPEN  lc_oprn_id;
    FETCH lc_oprn_id INTO ln_oprn_id;
    IF ( lc_oprn_id%NOTFOUND ) THEN
      CLOSE lc_oprn_id;
      RAISE oprn_id_err;
    END IF;
    CLOSE lc_oprn_id;
--
    -----------------------------
    --  �H���}�X�^���  �ҏW(�Œ蕔��)
    -----------------------------
    routings_b_rec.owner_orgn_code          := '2020';                  -- ���L�ґg�D�R�[�h
    routings_b_rec.process_loss             := 0;
    routings_b_rec.routing_vers             := 1;                       -- �H���o�[�W����
    routings_b_rec.routing_desc             := '�i�ڐU��';              -- �E�v(�uNULL�v�Œ�)
    routings_b_rec.routing_class            := '70';                    -- �H���敪(�u70�F�i�ڐU�ցv�Œ�)
    routings_b_rec.routing_qty              := 1;                       -- ����(�u1�v�Œ�)
    routings_b_rec.item_um                  := 'kg';                    -- �P��(�ukg�v�Œ�)
    routings_b_rec.attribute1               := '�i�ڐU��';              -- ���C�����E����(�u�i�ڐU�ցv�Œ�)
    routings_b_rec.attribute2               := '1';                     -- ���C���敪(�u1�F���Ѓ��C���v�Œ�)
    routings_b_rec.attribute13              := '31';                    -- �`�[�敪(�u31�F�ā@���v�Œ�)
    routings_b_rec.attribute14              := '2191';                  -- ���ъǗ�����(�u2191�F�d���Ǘ��ہv�Œ�)
    routings_b_rec.attribute15              := '1';                     -- ���O�敪(�u1�F���Ёv�Œ�)
    routings_b_rec.attribute16              := '2';                     -- �����i�敪(�u2�F���[�t�v�Œ�)
    routings_b_rec.attribute17              := 'N';                     -- �V�ʐ��敪(�uN�v�Œ�)
    routings_b_rec.attribute18              := 'N';                     -- ���M�Ώۃt���O(�uN�v�Œ�)
    routings_b_rec.attribute19              := 'ZZZZ';                  -- �ŗL�L��(�uZZZZ�v�Œ�)
    routings_b_rec.effective_start_date     := TO_DATE('20080401', 'YYYY/MM/DD');
--
    -----------------------------
    --  �H�����  �ҏW(�Œ蕔��)
    -----------------------------
    lt_routings_step_tab(1).routingstep_no  := 10;          --�H���ڍהԍ�
    lt_routings_step_tab(1).oprn_id         := ln_oprn_id;  --�H��ID
--
    --========================================================================
    --  �H���}�X�^���̒��o
    --========================================================================
    FOR locations_rec IN locations_cur LOOP
      --�S�̌����̃J�E���g�A�b�v
      gn_total_cnt := gn_total_cnt + 1;
      --�L�[���ڊi�[
      lt_routing_no := '9' || locations_rec.location;
      -----------------------------
      --  �H���}�X�^���  �ҏW(�ϓ�����)
      -----------------------------
      routings_b_rec.routing_no   := lt_routing_no;           -- �H��No
      routings_b_rec.attribute9   := locations_rec.location;  -- �[�i�ꏊ
      routings_b_rec.attribute21  := locations_rec.whse_code; -- �[�i�q��
--
      -----------------------------
      --  �H���o�^(EBS�W��API)
      -----------------------------
      GMD_ROUTINGS_PUB.INSERT_ROUTING(
          p_api_version           => 1.0                      -- API�o�[�W�����ԍ�
        , p_init_msg_list         => TRUE                     -- ���b�Z�[�W�������t���O
        , p_commit                => FALSE                    -- �����R�~�b�g�t���O
        , p_routings              => routings_b_rec           -- �H���e�[�u��
        , p_routings_step_tbl     => lt_routings_step_tab     -- �H���z��
        , p_routings_step_dep_tbl => lt_routings_step_dep_tab -- �_�~�[�H���z��
        , x_message_count         => ln_message_count         -- �G���[���b�Z�[�W����
        , x_message_list          => lv_msg_list              -- �G���[���b�Z�[�W
        , x_return_status         => lv_return_status         -- �v���Z�X�I���X�e�[�^�X
          );
      -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
      IF ( lv_return_status  <>  fnd_api.g_ret_sts_success ) THEN
--
        FOR cnt IN 1..ln_message_count LOOP
          lv_msg_date := fnd_msg_pub.get(cnt ,'F');
          DBMS_OUTPUT.PUT_LINE('EBS�W��API:' || lv_msg_date);
        END loop;
--
        lv_err_msg     := 'ERR:�H���}�X�^�o�^(EBS�W��API)(' || gv_proc_name || ')' || '(�L�[����:���C����=' || lt_routing_no || ')';
        lv_ret_status  := gv_status_error;
        RAISE sub_func_expt;
      END IF;
--
      BEGIN
        -- �H��ID�̎擾
        SELECT grb.routing_id
        INTO   routings_b_rec.routing_id
        FROM   gmd_routings_b grb   -- �H���}�X�^
        WHERE  grb.routing_no = lt_routing_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE global_api_expt;
      END;
--
      -----------------------------
      -- �H���X�e�[�^�X�ύX(EBS�W��API)
      -----------------------------
      GMD_STATUS_PUB.MODIFY_STATUS(
          p_api_version    => 1.0
        , p_init_msg_list  => TRUE
        , p_entity_name    => 'ROUTING'
        , p_entity_id      => routings_b_rec.routing_id
        , p_entity_no      => NULL            -- (NULL�Œ�)
        , p_entity_version => NULL            -- (NULL�Œ�)
        , p_to_status      => gv_fml_sts_appr
        , p_ignore_flag    => FALSE
        , x_message_count  => ln_message_count
        , x_message_list   => lv_msg_list
        , x_return_status  => lv_return_status
          );
--
      -- �X�e�[�^�X�ύX�����������łȂ��ꍇ
      IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN
        lv_err_msg    := xxcmn_common_pkg.get_msg(gv_msg_kbn_inv
                                                , gv_msg_52a_00
                                                , gv_tkn_api_name
                                                , gv_tkn_upd_routing);
        lv_ret_status := gv_status_error;
        RAISE global_api_expt;
      -- �X�e�[�^�X�ύX�����������̏ꍇ
      ELSIF ( lv_return_status = fnd_api.g_ret_sts_success ) THEN
        -- �m�菈��
        COMMIT;
      END IF;
--
    END LOOP;
--
  EXCEPTION
    WHEN oprn_id_err THEN
      IF ( locations_cur%ISOPEN ) THEN
          CLOSE  locations_cur;
      END IF;
      ov_err_msg     := 'ERR:�H��ID�擾���s(' 
                        || gv_proc_name || ')' || '(�L�[����:���C����=' || lt_routing_no || ')' || SQLCODE || ':' || SQLERRM ;
      ov_ret_status  := gv_status_error;
    WHEN global_api_expt THEN
      IF ( locations_cur%ISOPEN ) THEN
        CLOSE  locations_cur;
      END IF;
      ov_err_msg     := 'ERR:�Ó������[���X�e�[�^�X�ύX(EBS�W��API)���s(' 
                        || gv_proc_name || ')' || '(�L�[����:���C����=' || lt_routing_no || ')' || SQLCODE || ':' || SQLERRM ;
      ov_ret_status  := gv_status_error;
    WHEN sub_func_expt THEN
      IF ( locations_cur%ISOPEN ) THEN
        CLOSE  locations_cur;
      END IF;
      ov_err_msg     :=  lv_err_msg;
      ov_ret_status  :=  lv_ret_status;
    WHEN OTHERS THEN
      IF ( locations_cur%ISOPEN ) THEN
        CLOSE  locations_cur;
      END IF;
      ov_err_msg     := lv_err_msg;
      ov_ret_status  := lv_ret_status;
--
  END submain;
--
  /***************************************************************************
  * PUROCEDURE���Fmain
  * �@�\�T�v�@�@�F�H���}�X�^�o�^
  * �����@�@�@�@�F
  * ���ӎ����@�@�F
  ***************************************************************************/
  PROCEDURE main
  IS
--
    --========================================================================
    --  �G���[����
    --========================================================================
    ln_ret_status         NUMBER;          --  ���^�[���E�X�e�[�^�X
    lv_err_msg            VARCHAR2(2000);  --  �G���[�E���b�Z�[�W
--
  BEGIN
--
    gn_total_cnt      := 0;
--
    --=======================================================================
    --  �R���J�����g�w�b�_���O�o��
    --=======================================================================
    DBMS_OUTPUT.PUT_LINE('========== START:' || gv_pkg_name || ':�H���}�X�^�o�^  ==========');
--
    --========================================================================
    --  submain ����
    --========================================================================
    gv_proc_name  :=  'submain';
    submain(
      ov_ret_status  => ln_ret_status
    , ov_err_msg     => lv_err_msg
      );
    IF ( ln_ret_status <> gv_status_normal ) THEN
      RAISE sub_func_expt;
    END IF;
--
    --========================================================================
    --  �R���J�����g�t�b�_���O�o��
    --========================================================================
    DBMS_OUTPUT.PUT_LINE('�߂�l                    :' || gv_status_normal); --  ���^�[���E�R�[�h�i����j
    DBMS_OUTPUT.PUT_LINE('��������(routings )       :' || gn_total_cnt);
    DBMS_OUTPUT.PUT_LINE('========== END  :' || gv_pkg_name || ':�H���}�X�^�o�^  ==========');
--
  EXCEPTION
    WHEN sub_func_expt THEN
      DBMS_OUTPUT.PUT_LINE('�߂�l                    :' || gv_status_error); --  ���^�[���E�R�[�h�i�ُ�j
      DBMS_OUTPUT.PUT_LINE('�G���[�o�b�t�@            :' || lv_err_msg);
      DBMS_OUTPUT.PUT_LINE('��������(routings )       :' || gn_total_cnt);
      DBMS_OUTPUT.PUT_LINE('========== END  :' || gv_pkg_name || ':�H���}�X�^�o�^  ==========');
      ROLLBACK;
    WHEN OTHERS THEN
      lv_err_msg  := 'ERR:�H���}�X�^�o�^(EBS�W��API)' || gv_pkg_name || ':' || SQLCODE || ':' || SQLERRM ;
      DBMS_OUTPUT.PUT_LINE('�߂�l                    :' || gv_status_error); --  ���^�[���E�R�[�h�i�ُ�j
      DBMS_OUTPUT.PUT_LINE('�G���[�o�b�t�@            :' || lv_err_msg);
      DBMS_OUTPUT.PUT_LINE('��������(routings )       :' || gn_total_cnt);
      DBMS_OUTPUT.PUT_LINE('========== END  :' || gv_pkg_name || ':�H���}�X�^�o�^  ==========');
      ROLLBACK;
  END main;
--
END xxinv520004c;
/
