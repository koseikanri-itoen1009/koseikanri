CREATE OR REPLACE FORCE VIEW XXCFO_PO_DEPT_V(
/*************************************************************************
 * 
 * View Name       : XXCFO_PO_DEPT_V
 * Description     : �����ҕ���r���[
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2008/12/16    1.0  SCS �R�� �D   ����쐬
 *  2009/02/06    1.1  SCS ���c�E�l  [��QCFO_001]���Ə��A�h�I���}�X�^�̗L�����t�`�F�b�N��ǉ�
 ************************************************************************/
  location_code,                -- ���Ə��R�[�h
  location_short_name           -- ����
) AS
  SELECT hl.location_code               location_code            -- ���Ə��R�[�h
        ,xla.location_short_name        location_short_name      -- ����
    FROM hr_locations               hl           -- ���Ə��}�X�^
        ,xxcmn_locations_all        xla          -- ���Ə��A�h�I���}�X�^
        ,per_all_people_f           papf         -- �]�ƈ��}�X�^
        ,po_agents                  pa           -- �w���S���}�X�^
  WHERE hl.location_id       = xla.location_id              -- ���Ə��}�X�^.���Ə�ID = ���Ə��A�h�I���}�X�^.���Ə�ID
    AND TRUNC(SYSDATE) BETWEEN TRUNC(xla.start_date_active)             -- TRUNC(SYSDATE) BETWEEN TRUNC(���Ə��A�h�I���}�X�^.�K�p�J�n��)
                           AND TRUNC(NVL(xla.end_date_active, SYSDATE)) --                    AND TRUNC(NVL(���Ə��A�h�I���}�X�^.�K�p�I����,SYSDATE))
    AND pa.agent_id          = papf.person_id               -- �w���S���}�X�^.�w���S��ID = �]�ƈ��}�X�^.�]�ƈ�ID
    AND papf.attribute28     = hl.location_code             -- �]�ƈ��}�X�^.DFF28 = ���Ə��}�X�^.���Ə��R�[�h
    AND TRUNC(SYSDATE) BETWEEN TRUNC(pa.start_date_active)             -- TRUNC(SYSDATE) BETWEEN TRUNC(�w���S���}�X�^.�K�p�J�n��)
                           AND TRUNC(NVL(pa.end_date_active, SYSDATE)) --                    AND TRUNC(NVL(�w���S���}�X�^.�K�p�I����,SYSDATE))
    AND TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)             -- TRUNC(SYSDATE) BETWEEN TRUNC(�]�ƈ��}�X�^.�L���J�n��)
                           AND TRUNC(NVL(papf.effective_end_date, SYSDATE)) --                    AND TRUNC(NVL(�]�ƈ��}�X�^.�L���I����,SYSDATE))
    AND papf.current_employee_flag = 'Y'         -- �]�ƈ��}�X�^.���ݏ]�ƈ��t���O = 'Y'
  GROUP BY hl.location_code                      -- ���Ə��R�[�h
          ,xla.location_short_name               -- ����
/
