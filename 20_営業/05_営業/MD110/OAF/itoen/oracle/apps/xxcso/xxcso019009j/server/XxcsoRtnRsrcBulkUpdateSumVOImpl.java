/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcBulkUpdateSumVOImpl
* �T�v����   : �Ώێw�胊�[�W�����r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS�x���a��    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * �Ώێw�胊�[�W�����̃r���[�N���X�ł��B
 * @author  SCS�x���a��
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateSumVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param employeeNumber       �]�ƈ��ԍ�
   * @param fullName             �]�ƈ�����
   * @param routeNo              ���[�gNo
   *****************************************************************************
   */
  public void initQuery(
    String employeeNumber
   ,String fullName
   ,String routeNo
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, employeeNumber);
    setWhereClauseParam(1, fullName);
    setWhereClauseParam(2, routeNo);

    executeQuery();
  }
}