/*============================================================================
* �t�@�C���� : XxcsoInstallBaseSortColumnVORowImpl
* �T�v����   : �������ėp������ʁ^�\�[�g�����擾�r���[�s�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-23 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * �\�[�g�������擾���邽�߂̃r���[�s�N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBaseSortColumnVORowImpl extends OAViewRowImpl 
{


  protected static final int SORTCOLUMN = 0;
  protected static final int SORTDIRECTION = 1;
  protected static final int ENABLEFLAG = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBaseSortColumnVORowImpl()
  {
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute EnableFlag
   */
  public String getEnableFlag()
  {
    return (String)getAttributeInternal(ENABLEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EnableFlag
   */
  public void setEnableFlag(String value)
  {
    setAttributeInternal(ENABLEFLAG, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SORTCOLUMN:
        return getSortColumn();
      case SORTDIRECTION:
        return getSortDirection();
      case ENABLEFLAG:
        return getEnableFlag();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ENABLEFLAG:
        setEnableFlag((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SortDirection
   */
  public String getSortDirection()
  {
    return (String)getAttributeInternal(SORTDIRECTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SortDirection
   */
  public void setSortDirection(String value)
  {
    setAttributeInternal(SORTDIRECTION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SortColumn
   */
  public String getSortColumn()
  {
    return (String)getAttributeInternal(SORTCOLUMN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SortColumn
   */
  public void setSortColumn(String value)
  {
    setAttributeInternal(SORTCOLUMN, value);
  }
}