/*============================================================================
* �t�@�C���� : XxcsoEmpNameSummaryVORowImpl
* �T�v����   : �T�������󋵏Ɖ�^�����p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * �X�P�W���[�����[�W�����i�S���Җ��j���������邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoEmpNameSummaryVORowImpl extends OAViewRowImpl 
{

  protected static final int EMPNAME = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoEmpNameSummaryVORowImpl()
  {
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPNAME:
        return getEmpName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPNAME:
        setEmpName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmpName
   */
  public String getEmpName()
  {
    return (String)getAttributeInternal(EMPNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmpName
   */
  public void setEmpName(String value)
  {
    setAttributeInternal(EMPNAME, value);
  }





}