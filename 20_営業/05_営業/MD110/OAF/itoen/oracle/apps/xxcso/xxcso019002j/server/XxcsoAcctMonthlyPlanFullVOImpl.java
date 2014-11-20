/*============================================================================
* �t�@�C���� : XxcsoAcctMonthlyPlanFullVOImpl
* �T�v����   : ����v��(�����ڋq)�@�ڋq�ʔ���v�挎�ʃ��[�W�����r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * ����v��(�����ڋq)�@�ڋq�ʔ���v�挎�ʃ��[�W�����r���[�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctMonthlyPlanFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctMonthlyPlanFullVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏��������s���܂��B
   * @param baseCode          ���_�R�[�h
   * @param targetYearMonth   �Ώ۔N��
   * @param employeeNumber    �]�ƈ��ԍ�
   *****************************************************************************
   */
  public void initQuery(
    String baseCode
   ,String targetYearMonth
   ,String employeeNumber
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    
    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, targetYearMonth);
    setWhereClauseParam(index++, employeeNumber);

    executeQuery();
  }

}