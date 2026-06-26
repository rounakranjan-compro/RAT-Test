test.describe('Tags display with TAGS : prefix on TestCard', () => {    
  test('should show tags with "TAGS :" prefix and remove buttons', async ({ page }) => {
    await page.goto('http://localhost:5173');                           
                                                                        
    // Wait for at least one TestCard to appear                         
    const testCard = await page.getByRole('article');                   
    await expect(testCard).toBeVisible();                               
                                                                        
    // Find the tag elements inside a TestCard                          
    const tags = await testCard.locator('.inline-flex.items-center.gap-1.rounded-md.bg-indigo-600/20.border.border-indigo-500/30.px-2.py-0.5.text-xs.text-indigo-300');     
    await expect(tags).toHaveCount(1);                                  
                                                                        
    // Assert that at least one tag is visible                          
    const firstTag = await tags.first();                                
    await expect(firstTag).toBeVisible();                               
                                                                        
    // Assert the first visible tag text starts with "TAGS : "          
    const tagText = await firstTag.textContent();                       
    await expect(tagText).toContain('TAGS :');

    // Assert the format is exactly "TAGS : <tagname>"
    await expect(tagText).toMatch(/^TAGS : .+$/);

    // Assert the × remove button appears next to each tag
    const closeButton = await tags.locator('button');
    await expect(closeButton).toBeVisible();

    // Final assertion: confirm "TAGS :" prefix is present and the old format (without prefix) is NOT present
    await expect(page).not.toContainText(/^[^ ]+$/);
  });
});