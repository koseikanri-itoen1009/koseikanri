/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcBulkUpdateEmployeeVOImpl
* �T�v����   : ���_���S���c�ƈ��r���[�N���X
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
 * ���_���S���c�ƈ��̃r���[�N���X�ł��B
 * @author  SCS�x���a��
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateEmployeeVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateEmployeeVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param employeeNumber       �]�ƈ��ԍ�
   * @param baseCode             ���_�R�[�h
   *****************************************************************************
   */
  public void initQuery(
    String employeeNumber
   ,String baseCode
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, employeeNumber);
    setWhereClauseParam(1, baseCode);
    setWhereClauseParam(2, baseCode);

    executeQuery();
  }
}