/*============================================================================
* �t�@�C���� : XxcsoCsvQueryVOImpl
* �T�v����   : �T�������󋵏Ɖ�^CSV�o��Query�i�[�p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-28 1.0  SCS�������l  �V�K�쐬
* 2009-06-23 1.2  SCS�������l  [��Q0000102]CSV�o�͐��\���P�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
// 2009-06-23 [��Q0000102] Add Start
import oracle.jbo.domain.Number;
// 2009-06-23 [��Q0000102] Add End

/*******************************************************************************
 * CSV�o��Query�i�[�p�r���[�N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCsvQueryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoCsvQueryVOImpl()
  {
  }

// 2009-06-23 [��Q0000102] Add Start
  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param appDate     �w����t
   * @param resourceId  ���\�[�XID
   *****************************************************************************
   */
  public void initQuery(
    String appDate
   ,Number resourceId
  )
  {
    // ������
    setWhereClause(null);
    setWhereClauseParams(null);

    // �o�C���h�ւ̒l�̐ݒ�
    int idx = 0;
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);

    // SQL���s
    executeQuery();
  }
// 2009-06-23 [��Q0000102] Add End

}