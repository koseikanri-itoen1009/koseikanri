/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcBulkUpdateSumVOImpl
* �T�v����   : �Ώێw�胊�[�W�����r���[�N���X
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS�x���a��  �V�K�쐬
* 2010-03-23 1.1  SCS�������  [E_�{�ғ�_01942]�Ǘ������_�Ή�
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
   * @param baseCode             ���_�R�[�h
   * @param baseName             ���_��
   *****************************************************************************
   */
  public void initQuery(
    String employeeNumber
   ,String fullName
   ,String routeNo
// 2010-03-23 [E_�{�ғ�_01942] Add Start
   ,String baseCode
   ,String baseName
// 2010-03-23 [E_�{�ғ�_01942] Add End
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, employeeNumber);
    setWhereClauseParam(1, fullName);
    setWhereClauseParam(2, routeNo);
// 2010-03-23 [E_�{�ғ�_01942] Add Start
    setWhereClauseParam(3, baseCode);
    setWhereClauseParam(4, baseName);
// 2010-03-23 [E_�{�ғ�_01942] Add End

    executeQuery();
  }
}