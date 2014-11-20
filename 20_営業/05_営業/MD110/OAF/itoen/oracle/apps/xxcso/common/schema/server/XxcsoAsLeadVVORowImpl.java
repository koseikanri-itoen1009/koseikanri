/*============================================================================
* �t�@�C���� : XxcsoAsLeadVVORowImpl
* �T�v����   : ���k���擾�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * ���k�����擾���邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAsLeadVVORowImpl extends OAViewRowImpl 
{






  protected static final int LEADNUMBER = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAsLeadVVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LeadNumber
   */
  public String getLeadNumber()
  {
    return (String)getAttributeInternal(LEADNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LeadNumber
   */
  public void setLeadNumber(String value)
  {
    setAttributeInternal(LEADNUMBER, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case LEADNUMBER:
        return getLeadNumber();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case LEADNUMBER:
        setLeadNumber((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }



}