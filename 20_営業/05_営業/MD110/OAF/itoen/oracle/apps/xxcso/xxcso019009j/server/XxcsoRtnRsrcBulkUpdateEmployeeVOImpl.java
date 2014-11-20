/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcBulkUpdateEmployeeVOImpl
* �T�v����   : ���_���S���c�ƈ��r���[�N���X
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS�x���a��    �V�K�쐬
* 2010-03-23 1.1  SCS�������  [E_�{�ғ�_01942]�Ǘ������_�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
// 2010-03-23 [E_�{�ғ�_01942] Add Start
import oracle.jbo.domain.Date;
// 2010-03-23 [E_�{�ғ�_01942] Add End

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
   * @param baseCodeDate         �Ώۋ��_���t
   * @param baseCode             ���_�R�[�h
   *****************************************************************************
   */
  public void initQuery(
    String employeeNumber
// 2010-03-23 [E_�{�ғ�_01942] Add Start
   ,Date   baseCodeDate
// 2010-03-23 [E_�{�ғ�_01942] Add End
   ,String baseCode
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, employeeNumber);
// 2010-03-23 [E_�{�ғ�_01942] Add Start
    //setWhereClauseParam(1, baseCode);
    setWhereClauseParam(1, baseCodeDate);
// 2010-03-23 [E_�{�ғ�_01942] Add End
    setWhereClauseParam(2, baseCode);

    executeQuery();
  }
}