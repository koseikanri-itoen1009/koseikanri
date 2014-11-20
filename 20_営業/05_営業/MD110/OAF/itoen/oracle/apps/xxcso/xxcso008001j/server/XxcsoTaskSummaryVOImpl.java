/*============================================================================
* �t�@�C���� : XxcsoTaskSummaryVOImpl
* �T�v����   : �T�������󋵏Ɖ�^�����p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �X�P�W���[�����[�W�������������邽�߂̃r���[�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoTaskSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoTaskSummaryVOImpl()
  {
  }

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
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, resourceId);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);
    setWhereClauseParam(idx++, appDate);

    // SQL���s
    executeQuery();
  }
}